import numpy as np

from app.ml.pose import PoseSequence, NUM_LANDMARKS, LANDMARK_INDEX


def chain(start, heading, lengths, interior_angles, turn=1.0):
    points = [np.asarray(start, dtype=float)]
    psi = np.radians(heading)
    for i, length in enumerate(lengths):
        if i:
            psi += turn * (np.pi - np.radians(interior_angles[i - 1]))
        points.append(points[-1] + length * np.array([np.cos(psi), np.sin(psi)]))
    return points


def rep_fractions(reps, fps, rep_seconds=2.0, rest_seconds=0.5):
    rest = np.zeros(int(rest_seconds * fps))
    t = np.linspace(0, 2 * np.pi, int(rep_seconds * fps), endpoint=False)
    body = (1 - np.cos(t)) / 2
    pieces = [rest]
    for _ in range(reps):
        pieces += [body, rest]
    return np.concatenate(pieces)


def sequence_from_frames(frames, fps=30.0):
    data = np.zeros((len(frames), NUM_LANDMARKS, 4))
    data[:, :, 3] = 0.99
    for f, pose in enumerate(frames):
        anchor = (np.asarray(pose["left_hip"]) + np.asarray(pose["right_hip"])) / 2.0
        data[f, :, :2] = anchor
        for name, xy in pose.items():
            data[f, LANDMARK_INDEX[name], :2] = xy
    return PoseSequence(data, fps=fps, metadata={"synthetic": True})


def both_sides(name, xy):
    return {f"left_{name}": xy, f"right_{name}": xy}


def paired(points, width=0.0, axis=0):
    offset = np.zeros(2)
    offset[axis] = width
    pose = {}
    for name, xy in points.items():
        xy = np.asarray(xy, dtype=float)
        pose[f"left_{name}"] = xy
        pose[f"right_{name}"] = xy + offset
    return pose


def keyframe_sequence(top, bottom, reps, fps=30.0, rep_seconds=2.0):
    fractions = rep_fractions(reps, fps, rep_seconds=rep_seconds)
    frames = [{k: (1 - f) * top[k] + f * bottom[k] for k in top} for f in fractions]
    return sequence_from_frames(frames, fps)
