import numpy as np

from app.ml.pose import PoseSequence, NUM_LANDMARKS, LANDMARK_INDEX

SEGMENT = 0.2


def _place(frame, name, x, y, z=0.0, vis=0.99):
    frame[LANDMARK_INDEX[name]] = (x, y, z, vis)


def squat_frame(knee_angle_deg, torso_lean_deg=10.0, knee_valgus=0.0, half_width=0.05, heel_raise=0.0,
                hip_drop=0.0):
    frame = np.zeros((NUM_LANDMARKS, 4))
    frame[:, 3] = 0.99
    phi = np.radians((180.0 - knee_angle_deg) / 2.0)
    lean = np.radians(torso_lean_deg)
    for side, dx in (("left", -half_width), ("right", half_width)):
        ankle = np.array([0.5 + dx, 0.9])
        knee = ankle + SEGMENT * np.array([np.sin(phi), -np.cos(phi)])
        hip = knee + SEGMENT * np.array([-np.sin(phi), -np.cos(phi)])
        shoulder = hip + 0.3 * np.array([np.sin(lean), -np.cos(lean)])
        elbow = shoulder + np.array([0.05, 0.1])
        wrist = elbow + np.array([0.05, -0.05])
        valgus = -dx * knee_valgus * 4
        _place(frame, f"{side}_ankle", *ankle)
        _place(frame, f"{side}_heel", ankle[0] - 0.02, ankle[1] + 0.01 - heel_raise)
        _place(frame, f"{side}_foot_index", ankle[0] + 0.05, ankle[1] + 0.01)
        _place(frame, f"{side}_knee", knee[0] + valgus, knee[1])
        _place(frame, f"{side}_hip", hip[0], hip[1] + (hip_drop if side == "right" else 0.0))
        _place(frame, f"{side}_shoulder", *shoulder)
        _place(frame, f"{side}_elbow", *elbow)
        _place(frame, f"{side}_wrist", *wrist)
        for part in ("pinky", "index", "thumb"):
            _place(frame, f"{side}_{part}", *(wrist + np.array([0.01, 0.0])))
        _place(frame, f"{side}_ear", shoulder[0], shoulder[1] - 0.08)
        for part in ("eye", "eye_inner", "eye_outer"):
            _place(frame, f"{side}_{part}", shoulder[0] + 0.02, shoulder[1] - 0.1)
    nose = (frame[LANDMARK_INDEX["left_shoulder"], :2] + frame[LANDMARK_INDEX["right_shoulder"], :2]) / 2
    _place(frame, "nose", nose[0] + 0.03, nose[1] - 0.1)
    _place(frame, "mouth_left", nose[0] + 0.01, nose[1] - 0.06)
    _place(frame, "mouth_right", nose[0] + 0.03, nose[1] - 0.06)
    return frame


def labelled_recordings(subjects=6, recordings_per_subject=4, reps=3, seed=0):
    from app.ml.training import LabelledRecording
    rng = np.random.default_rng(seed)
    out = []
    for s in range(subjects):
        for r in range(recordings_per_subject):
            bottom = float(rng.uniform(70, 140))
            lean = float(rng.uniform(5, 55))
            seq = squat_sequence(reps=reps, bottom_angle=bottom, torso_lean_deg=lean,
                                 noise=0.002, seed=int(rng.integers(1_000_000)))
            label = {"shallow": int(bottom > 110), "forward_lean": int(lean > 35)}
            out.append(LabelledRecording(seq, f"subject_{s}", [dict(label) for _ in range(reps)],
                                         recording_id=f"s{s}_r{r}"))
    return out


def squat_sequence(reps=3, fps=30.0, rep_seconds=2.0, bottom_angle=80.0, top_angle=175.0,
                   torso_lean_deg=10.0, knee_valgus=0.0, noise=0.0, seed=0, rest_seconds=0.5,
                   half_width=0.05, heel_raise=0.0, hip_drop=0.0, lean_with_depth=False):
    rng = np.random.default_rng(seed)
    rest = int(rest_seconds * fps)
    rep_frames = int(rep_seconds * fps)
    angles = [top_angle] * rest
    for _ in range(reps):
        t = np.linspace(0, 2 * np.pi, rep_frames, endpoint=False)
        angles.extend(top_angle - (top_angle - bottom_angle) * (1 - np.cos(t)) / 2)
        angles.extend([top_angle] * rest)
    depth = (top_angle - np.array(angles)) / max(top_angle - bottom_angle, 1e-9)
    frames = np.stack([
        squat_frame(a, 5.0 + (torso_lean_deg - 5.0) * d if lean_with_depth else torso_lean_deg,
                    knee_valgus * d, half_width, heel_raise * d, hip_drop * d)
        for a, d in zip(angles, depth)
    ])
    if noise:
        frames[:, :, :2] += rng.normal(0, noise, frames[:, :, :2].shape)
    return PoseSequence(frames, fps=fps, metadata={"synthetic": True, "reps": reps})
