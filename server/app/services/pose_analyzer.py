"""
Pose-Based Video Analysis Service

Uses MediaPipe Pose for real biomechanical analysis of workout videos.
Calculates actual metrics from joint positions and angles.
"""

import cv2
import numpy as np
import mediapipe as mp
from mediapipe.python.solutions import pose as mp_pose
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
import uuid
import math


class PoseAnalyzer:
    """
    Analyzes workout videos using MediaPipe Pose detection.
    
    Provides real biomechanical analysis:
    - Joint angle calculations
    - Range of motion tracking
    - Body alignment assessment
    - Movement stability analysis
    - Tempo/rhythm analysis
    """
    
    # MediaPipe Pose landmarks
    LANDMARKS = {
        'nose': 0,
        'left_shoulder': 11, 'right_shoulder': 12,
        'left_elbow': 13, 'right_elbow': 14,
        'left_wrist': 15, 'right_wrist': 16,
        'left_hip': 23, 'right_hip': 24,
        'left_knee': 25, 'right_knee': 26,
        'left_ankle': 27, 'right_ankle': 28,
        'left_heel': 29, 'right_heel': 30,
        'left_foot_index': 31, 'right_foot_index': 32
    }
    
    # Exercise detection patterns based on joint movements
    EXERCISE_PATTERNS = {
        'squat': {'primary_joints': ['left_knee', 'right_knee', 'left_hip', 'right_hip'],
                  'movement': 'vertical', 'knee_angle_range': (60, 170)},
        'lunge': {'primary_joints': ['left_knee', 'right_knee', 'left_hip', 'right_hip'],
                  'movement': 'asymmetric_vertical', 'knee_angle_range': (70, 170)},
        'pushup': {'primary_joints': ['left_elbow', 'right_elbow', 'left_shoulder', 'right_shoulder'],
                   'movement': 'horizontal', 'elbow_angle_range': (60, 170)},
        'deadlift': {'primary_joints': ['left_hip', 'right_hip', 'left_knee', 'right_knee'],
                     'movement': 'hip_hinge', 'hip_angle_range': (90, 180)},
        'shoulder_press': {'primary_joints': ['left_elbow', 'right_elbow', 'left_shoulder', 'right_shoulder'],
                           'movement': 'overhead', 'elbow_angle_range': (60, 180)},
        'bicep_curl': {'primary_joints': ['left_elbow', 'right_elbow'],
                       'movement': 'curl', 'elbow_angle_range': (30, 160)},
        'plank': {'primary_joints': ['left_shoulder', 'right_shoulder', 'left_hip', 'right_hip'],
                  'movement': 'static', 'body_angle_range': (160, 180)},
        'row': {'primary_joints': ['left_elbow', 'right_elbow', 'left_shoulder', 'right_shoulder'],
                'movement': 'pull', 'elbow_angle_range': (40, 170)}
    }
    
    # Feedback templates
    FEEDBACK_TEMPLATES = {
        "depth": {
            "high": "Excellent depth! You're achieving full range of motion.",
            "medium": "Try to go a bit deeper for maximum muscle engagement.",
            "low": "Your depth is limited. Focus on gradually increasing range."
        },
        "alignment": {
            "high": "Great body alignment! Core is stable and spine is neutral.",
            "medium": "Watch your alignment - keep your back straight and core engaged.",
            "low": "Body alignment needs attention. Focus on keeping spine neutral."
        },
        "stability": {
            "high": "Very stable movement with minimal wobble. Excellent control!",
            "medium": "Some instability detected. Engage your core more.",
            "low": "Movement is unstable. Reduce weight and focus on control."
        },
        "tempo": {
            "high": "Perfect tempo! Controlled and consistent throughout.",
            "medium": "Try to maintain more consistent speed during the movement.",
            "low": "Movement is too fast. Slow down for better muscle engagement."
        },
        "range_of_motion": {
            "high": "Full range of motion achieved throughout the exercise!",
            "medium": "You can extend your range for better results.",
            "low": "Limited range of motion. Work on flexibility."
        }
    }
    
    # Skeleton connections for drawing
    POSE_CONNECTIONS = [
        # Torso
        (11, 12), (11, 23), (12, 24), (23, 24),
        # Left arm
        (11, 13), (13, 15),
        # Right arm
        (12, 14), (14, 16),
        # Left leg
        (23, 25), (25, 27), (27, 29), (27, 31),
        # Right leg
        (24, 26), (26, 28), (28, 30), (28, 32),
    ]
    
    # Ideal angles for exercises (target ranges)
    IDEAL_ANGLES = {
        'squat': {'knee': (80, 100), 'hip': (70, 90)},
        'lunge': {'knee': (80, 100), 'hip': (80, 110)},
        'pushup': {'elbow': (80, 100)},
        'deadlift': {'hip': (90, 120), 'knee': (150, 170)},
        'bicep_curl': {'elbow': (30, 50)},
        'shoulder_press': {'elbow': (160, 180)},
    }
    
    def __init__(self, output_dir: str = "/app/data/output"):
        """Initialize MediaPipe Pose detector."""
        self.pose = mp_pose.Pose(
            static_image_mode=False,
            model_complexity=2,  # 0, 1, or 2 - higher is more accurate
            enable_segmentation=False,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        self.output_dir = output_dir
        import os
        os.makedirs(output_dir, exist_ok=True)
        print("[PoseAnalyzer] MediaPipe Pose initialized")
    
    def _calculate_angle(self, a: np.ndarray, b: np.ndarray, c: np.ndarray) -> float:
        """
        Calculate angle at point b given three points a, b, c.
        
        Args:
            a, b, c: Points as numpy arrays [x, y, z]
            
        Returns:
            Angle in degrees (0-180)
        """
        ba = a - b
        bc = c - b
        
        cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
        cosine_angle = np.clip(cosine_angle, -1.0, 1.0)
        angle = np.arccos(cosine_angle)
        
        return np.degrees(angle)
    
    def _get_landmark_coords(self, landmarks, idx: int) -> np.ndarray:
        """Extract x, y, z coordinates from a landmark."""
        lm = landmarks.landmark[idx]
        return np.array([lm.x, lm.y, lm.z])
    
    def _get_score_color(self, score: float) -> Tuple[int, int, int]:
        """Get BGR color based on score (0-100)."""
        if score >= 80:
            return (0, 255, 0)  # Green - good
        elif score >= 50:
            return (0, 255, 255)  # Yellow - needs work
        else:
            return (0, 0, 255)  # Red - poor
    
    def _draw_skeleton(
        self, 
        frame: np.ndarray, 
        landmarks, 
        angles: Dict[str, float],
        exercise: str,
        frame_scores: Dict[str, float]
    ) -> np.ndarray:
        """
        Draw pose skeleton on frame with color-coded feedback.
        
        Args:
            frame: BGR image
            landmarks: MediaPipe pose landmarks
            angles: Current joint angles
            exercise: Detected exercise type
            frame_scores: Current frame's scores
        
        Returns:
            Annotated frame
        """
        h, w = frame.shape[:2]
        annotated = frame.copy()
        
        # Get overall color based on average score
        avg_score = np.mean(list(frame_scores.values())) if frame_scores else 50
        main_color = self._get_score_color(avg_score)
        
        # Draw connections (skeleton lines)
        for connection in self.POSE_CONNECTIONS:
            start_idx, end_idx = connection
            
            start = landmarks.landmark[start_idx]
            end = landmarks.landmark[end_idx]
            
            if start.visibility > 0.5 and end.visibility > 0.5:
                start_point = (int(start.x * w), int(start.y * h))
                end_point = (int(end.x * w), int(end.y * h))
                
                # Color based on body part
                if start_idx in [23, 24, 25, 26, 27, 28]:  # Legs
                    color = self._get_score_color(frame_scores.get('depth', 50))
                elif start_idx in [11, 12, 23, 24]:  # Torso
                    color = self._get_score_color(frame_scores.get('alignment', 50))
                else:
                    color = main_color
                
                cv2.line(annotated, start_point, end_point, color, 3)
        
        # Draw joint circles
        for idx in [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28]:
            lm = landmarks.landmark[idx]
            if lm.visibility > 0.5:
                point = (int(lm.x * w), int(lm.y * h))
                cv2.circle(annotated, point, 6, main_color, -1)
                cv2.circle(annotated, point, 6, (255, 255, 255), 2)
        
        # Draw angle annotations at key joints
        angle_positions = {
            'left_knee': (25, 'L Knee'),
            'right_knee': (26, 'R Knee'),
            'left_elbow': (13, 'L Elbow'),
            'right_elbow': (14, 'R Elbow'),
            'left_hip': (23, 'L Hip'),
            'right_hip': (24, 'R Hip'),
        }
        
        for angle_name, (idx, label) in angle_positions.items():
            if angle_name in angles:
                lm = landmarks.landmark[idx]
                if lm.visibility > 0.5:
                    point = (int(lm.x * w) + 10, int(lm.y * h) - 10)
                    angle_val = angles[angle_name]
                    
                    # Check if angle is in ideal range
                    ideal = self.IDEAL_ANGLES.get(exercise, {})
                    joint_type = angle_name.split('_')[1]  # knee, elbow, hip
                    ideal_range = ideal.get(joint_type, (0, 180))
                    
                    if ideal_range[0] <= angle_val <= ideal_range[1]:
                        color = (0, 255, 0)  # Green - in range
                    elif abs(angle_val - ideal_range[0]) < 20 or abs(angle_val - ideal_range[1]) < 20:
                        color = (0, 255, 255)  # Yellow - close
                    else:
                        color = (0, 0, 255)  # Red - out of range
                    
                    cv2.putText(annotated, f"{angle_val:.0f}°", point, 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
        
        return annotated
    
    def _draw_ideal_guide(
        self,
        frame: np.ndarray,
        landmarks,
        exercise: str,
        angles: Dict[str, float]
    ) -> np.ndarray:
        """
        Draw ideal form guide lines showing where joints should be.
        
        Args:
            frame: BGR image
            landmarks: MediaPipe landmarks
            exercise: Exercise type
            angles: Current angles
        
        Returns:
            Frame with guide lines
        """
        h, w = frame.shape[:2]
        annotated = frame.copy()
        
        ideal = self.IDEAL_ANGLES.get(exercise, {})
        
        # ALWAYS draw ideal "ghost" skeleton showing correct form
        # Bright cyan color for high visibility (BGR format)
        IDEAL_COLOR = (255, 255, 0)  # Bright cyan
        IDEAL_THICKNESS = 4  # Thicker for visibility
        
        # Debug: print exercise being processed
        print(f"[DEBUG] _draw_ideal_guide called - exercise: '{exercise}', ideal keys: {ideal.keys()}")
        
        # Add "IDEAL FORM" label in top-right
        cv2.putText(annotated, "--- Ideal Form", 
                   (w - 150, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.5, IDEAL_COLOR, 2)
        
        # Lower visibility threshold to 0.3 for better detection
        MIN_VISIBILITY = 0.3
        
        if exercise in ['squat', 'lunge'] and 'knee' in ideal:
            print(f"[DEBUG] Drawing squat/lunge ideal form")
            ideal_knee_min, ideal_knee_max = ideal['knee']
            target_knee_angle = (ideal_knee_min + ideal_knee_max) / 2  # ~90 degrees
            
            for side, knee_idx, hip_idx, ankle_idx in [
                ('left', 25, 23, 27), ('right', 26, 24, 28)
            ]:
                knee_lm = landmarks.landmark[knee_idx]
                hip_lm = landmarks.landmark[hip_idx]
                ankle_lm = landmarks.landmark[ankle_idx]
                
                # Use lower visibility threshold
                vis_ok = all(lm.visibility > MIN_VISIBILITY for lm in [knee_lm, hip_lm, ankle_lm])
                print(f"[DEBUG] {side} leg visibility - knee: {knee_lm.visibility:.2f}, hip: {hip_lm.visibility:.2f}, ankle: {ankle_lm.visibility:.2f}, OK: {vis_ok}")
                
                if vis_ok:
                    # Get ACTUAL positions from user
                    knee_pt = np.array([knee_lm.x * w, knee_lm.y * h])
                    hip_pt = np.array([hip_lm.x * w, hip_lm.y * h])
                    ankle_pt = np.array([ankle_lm.x * w, ankle_lm.y * h])
                    
                    # Calculate actual segment lengths
                    thigh_length = np.linalg.norm(knee_pt - hip_pt)
                    shin_length = np.linalg.norm(ankle_pt - knee_pt)
                    
                    # IDEAL FORM: Anchor at user's ACTUAL hip
                    # Follow the DIRECTION of user's leg but show proper squat depth
                    
                    ideal_hip_pt = hip_pt.copy()
                    
                    # Get direction vectors from user's actual pose
                    hip_to_knee_dir = knee_pt - hip_pt
                    hip_to_knee_unit = hip_to_knee_dir / (np.linalg.norm(hip_to_knee_dir) + 1e-6)
                    
                    knee_to_ankle_dir = ankle_pt - knee_pt
                    knee_to_ankle_unit = knee_to_ankle_dir / (np.linalg.norm(knee_to_ankle_dir) + 1e-6)
                    
                    # Ideal knee: follow same direction as user's thigh but ensure proper depth
                    # For 90-deg squat, knee should be lower (thigh more horizontal)
                    # Blend user's direction with more vertical drop
                    ideal_knee_pt = ideal_hip_pt + hip_to_knee_unit * thigh_length
                    # Adjust: move knee slightly more outward and down for better squat depth
                    ideal_knee_pt[1] = max(ideal_knee_pt[1], hip_pt[1] + thigh_length * 0.7)
                    
                    # Ideal ankle: follow same general direction as user's shin
                    # For proper squat, shin should be more vertical
                    ideal_ankle_pt = ideal_knee_pt + knee_to_ankle_unit * shin_length
                    
                    # Draw ideal skeleton - SOLID cyan lines
                    # Hip to ideal knee (thigh)
                    cv2.line(annotated, 
                            (int(ideal_hip_pt[0]), int(ideal_hip_pt[1])),
                            (int(ideal_knee_pt[0]), int(ideal_knee_pt[1])),
                            IDEAL_COLOR, IDEAL_THICKNESS)
                    
                    # Ideal knee to ideal ankle (shin)
                    cv2.line(annotated, 
                            (int(ideal_knee_pt[0]), int(ideal_knee_pt[1])),
                            (int(ideal_ankle_pt[0]), int(ideal_ankle_pt[1])),
                            IDEAL_COLOR, IDEAL_THICKNESS)
                    
                    # Draw ideal joint circles
                    cv2.circle(annotated, (int(ideal_hip_pt[0]), int(ideal_hip_pt[1])), 
                              10, IDEAL_COLOR, 2)
                    cv2.circle(annotated, (int(ideal_knee_pt[0]), int(ideal_knee_pt[1])), 
                              14, IDEAL_COLOR, 3)
                    cv2.circle(annotated, (int(ideal_ankle_pt[0]), int(ideal_ankle_pt[1])), 
                              10, IDEAL_COLOR, 2)
                    
                    # Show target angle label near knee
                    cv2.putText(annotated, f"{target_knee_angle:.0f}°", 
                               (int(ideal_knee_pt[0]) + 10, int(ideal_knee_pt[1]) - 10),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.6, IDEAL_COLOR, 2)
                    print(f"[DEBUG] Drew ideal form for {side} leg")
                else:
                    # Visibility too low - add a text indicator
                    cv2.putText(annotated, f"({side[0].upper()}) Low visibility", 
                               (20, h - 50 if side == 'left' else h - 30),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 165, 255), 1)
            
            # UPPER BODY ideal form for squat - show upright torso
            # Landmarks: 11/12 = shoulders, 23/24 = hips, 0 = nose
            left_shoulder = landmarks.landmark[11]
            right_shoulder = landmarks.landmark[12]
            left_hip = landmarks.landmark[23]
            right_hip = landmarks.landmark[24]
            nose = landmarks.landmark[0]
            
            # Check visibility
            upper_vis_ok = all(lm.visibility > MIN_VISIBILITY for lm in 
                              [left_shoulder, right_shoulder, left_hip, right_hip])
            print(f"[DEBUG] upper body visibility - shoulders: {left_shoulder.visibility:.2f}/{right_shoulder.visibility:.2f}, hips: {left_hip.visibility:.2f}/{right_hip.visibility:.2f}, OK: {upper_vis_ok}")
            
            if upper_vis_ok:
                # Get actual positions
                l_shoulder_pt = np.array([left_shoulder.x * w, left_shoulder.y * h])
                r_shoulder_pt = np.array([right_shoulder.x * w, right_shoulder.y * h])
                l_hip_pt = np.array([left_hip.x * w, left_hip.y * h])
                r_hip_pt = np.array([right_hip.x * w, right_hip.y * h])
                
                # Calculate midpoints
                mid_shoulder = (l_shoulder_pt + r_shoulder_pt) / 2
                mid_hip = (l_hip_pt + r_hip_pt) / 2
                
                # Torso length (hip to shoulder)
                torso_length = np.linalg.norm(mid_shoulder - mid_hip)
                
                # IDEAL: Anchor at user's ACTUAL shoulder X positions
                # Only adjust Y to show proper upright posture
                # For proper squat: shoulders should be nearly above hips
                
                # Ideal Y: shoulders should be ~torso_length above hips (upright)
                ideal_shoulder_y = mid_hip[1] - torso_length * 0.95
                
                # Keep X positions SAME as actual shoulders (anchored to user's body)
                ideal_l_shoulder = np.array([l_shoulder_pt[0], ideal_shoulder_y])
                ideal_r_shoulder = np.array([r_shoulder_pt[0], ideal_shoulder_y])
                ideal_mid_shoulder = (ideal_l_shoulder + ideal_r_shoulder) / 2
                
                # Draw ideal shoulder line (anchored to actual shoulder X positions)
                cv2.line(annotated,
                        (int(ideal_l_shoulder[0]), int(ideal_l_shoulder[1])),
                        (int(ideal_r_shoulder[0]), int(ideal_r_shoulder[1])),
                        IDEAL_COLOR, IDEAL_THICKNESS)
                
                # Draw ideal torso spine (mid hip to mid shoulder)
                cv2.line(annotated,
                        (int(mid_hip[0]), int(mid_hip[1])),
                        (int(ideal_mid_shoulder[0]), int(ideal_mid_shoulder[1])),
                        IDEAL_COLOR, IDEAL_THICKNESS)
                
                # Draw ideal hip line
                cv2.line(annotated,
                        (int(l_hip_pt[0]), int(l_hip_pt[1])),
                        (int(r_hip_pt[0]), int(r_hip_pt[1])),
                        IDEAL_COLOR, IDEAL_THICKNESS)
                
                # Connect shoulders to corresponding hips
                cv2.line(annotated,
                        (int(ideal_l_shoulder[0]), int(ideal_l_shoulder[1])),
                        (int(l_hip_pt[0]), int(l_hip_pt[1])),
                        IDEAL_COLOR, IDEAL_THICKNESS)
                cv2.line(annotated,
                        (int(ideal_r_shoulder[0]), int(ideal_r_shoulder[1])),
                        (int(r_hip_pt[0]), int(r_hip_pt[1])),
                        IDEAL_COLOR, IDEAL_THICKNESS)
                
                # Head position - above mid shoulder
                if nose.visibility > MIN_VISIBILITY:
                    nose_pt = np.array([nose.x * w, nose.y * h])
                    head_to_shoulder = np.linalg.norm(nose_pt - mid_shoulder)
                    ideal_head_pt = ideal_mid_shoulder + np.array([0, -head_to_shoulder * 0.8])
                    
                    cv2.line(annotated,
                            (int(ideal_mid_shoulder[0]), int(ideal_mid_shoulder[1])),
                            (int(ideal_head_pt[0]), int(ideal_head_pt[1])),
                            IDEAL_COLOR, IDEAL_THICKNESS)
                    cv2.circle(annotated, (int(ideal_head_pt[0]), int(ideal_head_pt[1])),
                              12, IDEAL_COLOR, 2)
                
                # Joint circles
                cv2.circle(annotated, (int(ideal_mid_shoulder[0]), int(ideal_mid_shoulder[1])),
                          8, IDEAL_COLOR, 2)
                cv2.circle(annotated, (int(ideal_l_shoulder[0]), int(ideal_l_shoulder[1])),
                          10, IDEAL_COLOR, 2)
                cv2.circle(annotated, (int(ideal_r_shoulder[0]), int(ideal_r_shoulder[1])),
                          10, IDEAL_COLOR, 2)
                
                # Label
                cv2.putText(annotated, "Chest up!", 
                           (int(ideal_mid_shoulder[0]) + 15, int(ideal_mid_shoulder[1])),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, IDEAL_COLOR, 2)
                print(f"[DEBUG] Drew ideal form for upper body (squat)")
        
        elif exercise == 'pushup' and 'elbow' in ideal:
            print(f"[DEBUG] Drawing pushup ideal form")
            ideal_elbow_min, ideal_elbow_max = ideal['elbow']
            target_elbow = (ideal_elbow_min + ideal_elbow_max) / 2  # ~90 degrees
            
            for side, elbow_idx, shoulder_idx, wrist_idx in [
                ('left', 13, 11, 15), ('right', 14, 12, 16)
            ]:
                elbow_lm = landmarks.landmark[elbow_idx]
                shoulder_lm = landmarks.landmark[shoulder_idx]
                wrist_lm = landmarks.landmark[wrist_idx]
                
                # Use lower visibility threshold
                vis_ok = all(lm.visibility > MIN_VISIBILITY for lm in [elbow_lm, shoulder_lm, wrist_lm])
                print(f"[DEBUG] {side} arm visibility - elbow: {elbow_lm.visibility:.2f}, shoulder: {shoulder_lm.visibility:.2f}, wrist: {wrist_lm.visibility:.2f}, OK: {vis_ok}")
                
                if vis_ok:
                    # Get ACTUAL positions
                    elbow_pt = np.array([elbow_lm.x * w, elbow_lm.y * h])
                    shoulder_pt = np.array([shoulder_lm.x * w, shoulder_lm.y * h])
                    wrist_pt = np.array([wrist_lm.x * w, wrist_lm.y * h])
                    
                    upper_arm_length = np.linalg.norm(elbow_pt - shoulder_pt)
                    forearm_length = np.linalg.norm(wrist_pt - elbow_pt)
                    
                    # IDEAL FORM: Anchor at user's ACTUAL wrist (hands stay on ground)
                    # For proper pushup at 90 degrees:
                    # - Forearm should be vertical (pointing up)
                    # - Upper arm should be roughly horizontal (pointing toward body)
                    
                    ideal_wrist_pt = wrist_pt.copy()
                    
                    # Calculate ideal elbow: straight up from wrist
                    ideal_elbow_x = ideal_wrist_pt[0]
                    ideal_elbow_y = ideal_wrist_pt[1] - forearm_length  # Straight up
                    ideal_elbow_pt = np.array([ideal_elbow_x, ideal_elbow_y])
                    
                    # Calculate ideal shoulder: horizontal from elbow toward body
                    direction = 1 if side == 'left' else -1  # Point toward center
                    ideal_shoulder_x = ideal_elbow_pt[0] + upper_arm_length * direction
                    ideal_shoulder_y = ideal_elbow_pt[1]  # Same height as elbow
                    ideal_shoulder_pt = np.array([ideal_shoulder_x, ideal_shoulder_y])
                    
                    # Draw ideal arm
                    cv2.line(annotated,
                            (int(ideal_wrist_pt[0]), int(ideal_wrist_pt[1])),
                            (int(ideal_elbow_pt[0]), int(ideal_elbow_pt[1])),
                            IDEAL_COLOR, IDEAL_THICKNESS)
                    
                    cv2.line(annotated,
                            (int(ideal_elbow_pt[0]), int(ideal_elbow_pt[1])),
                            (int(ideal_shoulder_pt[0]), int(ideal_shoulder_pt[1])),
                            IDEAL_COLOR, IDEAL_THICKNESS)
                    
                    # Draw ideal joint circles
                    cv2.circle(annotated, (int(ideal_wrist_pt[0]), int(ideal_wrist_pt[1])),
                              10, IDEAL_COLOR, 2)
                    cv2.circle(annotated, (int(ideal_elbow_pt[0]), int(ideal_elbow_pt[1])),
                              14, IDEAL_COLOR, 3)
                    cv2.circle(annotated, (int(ideal_shoulder_pt[0]), int(ideal_shoulder_pt[1])),
                              10, IDEAL_COLOR, 2)
                    
                    cv2.putText(annotated, f"{target_elbow:.0f}°",
                               (int(ideal_elbow_pt[0]) + 10, int(ideal_elbow_pt[1]) - 10),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.6, IDEAL_COLOR, 2)
                    print(f"[DEBUG] Drew ideal form for {side} arm (pushup)")
                else:
                    # Visibility too low
                    cv2.putText(annotated, f"({side[0].upper()}) Low arm visibility", 
                               (20, h - 50 if side == 'left' else h - 30),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 165, 255), 1)
        
        elif exercise == 'bicep_curl' and 'elbow' in ideal:
            print(f"[DEBUG] Drawing bicep_curl ideal form")
            ideal_elbow_min, ideal_elbow_max = ideal['elbow']
            target_elbow = (ideal_elbow_min + ideal_elbow_max) / 2
            
            for side, elbow_idx, shoulder_idx, wrist_idx in [
                ('left', 13, 11, 15), ('right', 14, 12, 16)
            ]:
                elbow_lm = landmarks.landmark[elbow_idx]
                shoulder_lm = landmarks.landmark[shoulder_idx]
                wrist_lm = landmarks.landmark[wrist_idx]
                
                if all(lm.visibility > MIN_VISIBILITY for lm in [elbow_lm, shoulder_lm, wrist_lm]):
                    elbow_pt = np.array([elbow_lm.x * w, elbow_lm.y * h])
                    shoulder_pt = np.array([shoulder_lm.x * w, shoulder_lm.y * h])
                    wrist_pt = np.array([wrist_lm.x * w, wrist_lm.y * h])
                    
                    forearm_length = np.linalg.norm(wrist_pt - elbow_pt)
                    
                    # Offset for visibility
                    offset_x = 30 if side == 'right' else -30
                    
                    ideal_elbow_pt = elbow_pt + np.array([offset_x, 0])
                    # Ideal wrist position (fully curled - wrist up near shoulder)
                    ideal_wrist_pt = ideal_elbow_pt + np.array([0, -forearm_length * 0.85])
                    
                    # Draw ideal forearm
                    cv2.line(annotated,
                            (int(ideal_elbow_pt[0]), int(ideal_elbow_pt[1])),
                            (int(ideal_wrist_pt[0]), int(ideal_wrist_pt[1])),
                            IDEAL_COLOR, IDEAL_THICKNESS)
                    
                    cv2.circle(annotated, (int(ideal_elbow_pt[0]), int(ideal_elbow_pt[1])),
                              12, IDEAL_COLOR, 3)
                    cv2.circle(annotated, (int(ideal_wrist_pt[0]), int(ideal_wrist_pt[1])),
                              10, IDEAL_COLOR, 3)
                    
                    cv2.putText(annotated, f"~{target_elbow:.0f}°",
                               (int(ideal_wrist_pt[0]) + 10, int(ideal_wrist_pt[1])),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.5, IDEAL_COLOR, 2)
        
        else:
            # Unknown exercise - show debug text
            print(f"[DEBUG] Unknown exercise for ideal form: '{exercise}'")
            cv2.putText(annotated, f"Exercise: {exercise}", 
                       (w - 200, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 255), 1)
        
        return annotated
    
    def _draw_dashed_line(self, img: np.ndarray, pt1: Tuple[int, int], pt2: Tuple[int, int], 
                          color: Tuple[int, int, int], thickness: int, dash_length: int = 10):
        """Draw a dashed line between two points."""
        dist = np.sqrt((pt2[0] - pt1[0])**2 + (pt2[1] - pt1[1])**2)
        if dist < 1:
            return
        dashes = int(dist / dash_length)
        if dashes < 1:
            dashes = 1
        
        for i in range(0, dashes, 2):
            start = (
                int(pt1[0] + (pt2[0] - pt1[0]) * i / dashes),
                int(pt1[1] + (pt2[1] - pt1[1]) * i / dashes)
            )
            end = (
                int(pt1[0] + (pt2[0] - pt1[0]) * min(i + 1, dashes) / dashes),
                int(pt1[1] + (pt2[1] - pt1[1]) * min(i + 1, dashes) / dashes)
            )
            cv2.line(img, start, end, color, thickness)
    
    def _draw_score_overlay(
        self,
        frame: np.ndarray,
        scores: Dict[str, float],
        quality_score: float,
        exercise: str
    ) -> np.ndarray:
        """Draw score overlay on frame."""
        h, w = frame.shape[:2]
        annotated = frame.copy()
        
        # Semi-transparent background for scores
        overlay = annotated.copy()
        cv2.rectangle(overlay, (10, 10), (200, 180), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.6, annotated, 0.4, 0, annotated)
        
        # Exercise name
        cv2.putText(annotated, exercise.replace('_', ' ').title(),
                   (20, 35), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        # Overall score with color
        score_color = self._get_score_color(quality_score)
        cv2.putText(annotated, f"Score: {quality_score:.0f}/100",
                   (20, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.5, score_color, 2)
        
        # Individual scores
        y_offset = 80
        for aspect, score in list(scores.items())[:3]:  # Show top 3
            color = self._get_score_color(score)
            label = aspect.replace('_', ' ').title()[:10]
            cv2.putText(annotated, f"{label}: {score:.0f}",
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.4, color, 1)
            y_offset += 18
        
        # Legend for skeleton colors
        y_offset += 10
        cv2.putText(annotated, "Legend:", (20, y_offset), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.35, (255, 255, 255), 1)
        y_offset += 15
        
        # Actual skeleton colors
        cv2.line(annotated, (20, y_offset - 3), (40, y_offset - 3), (0, 255, 0), 2)
        cv2.putText(annotated, "Good", (45, y_offset), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.3, (200, 200, 200), 1)
        
        cv2.line(annotated, (85, y_offset - 3), (105, y_offset - 3), (0, 255, 255), 2)
        cv2.putText(annotated, "OK", (110, y_offset), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.3, (200, 200, 200), 1)
        
        cv2.line(annotated, (135, y_offset - 3), (155, y_offset - 3), (0, 0, 255), 2)
        cv2.putText(annotated, "Fix", (160, y_offset), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.3, (200, 200, 200), 1)
        
        y_offset += 15
        # Ideal form legend (dashed cyan/blue)
        for i in range(0, 20, 4):
            cv2.line(annotated, (20 + i, y_offset - 3), (22 + i, y_offset - 3), (255, 180, 0), 2)
        cv2.putText(annotated, "Ideal form", (45, y_offset), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.3, (255, 180, 0), 1)
        
        return annotated
    
    def _generate_annotated_video(
        self,
        video_path: str,
        exercise: str,
        form_scores: Dict[str, float],
        quality_score: float
    ) -> Optional[str]:
        """
        Generate annotated video with pose overlay and feedback.
        
        Returns path to the generated video file.
        """
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            return None
        
        fps = cap.get(cv2.CAP_PROP_FPS) or 30
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # Output filename
        output_filename = f"annotated_{uuid.uuid4().hex[:8]}.mp4"
        output_path = f"{self.output_dir}/{output_filename}"
        
        # Video writer (H.264 codec for web compatibility)
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
        
        if not out.isOpened():
            cap.release()
            return None
        
        frame_count = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Process pose
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self.pose.process(rgb_frame)
            
            if results.pose_landmarks:
                landmarks = results.pose_landmarks
                
                # Calculate angles for this frame
                angles = {}
                joints = {}
                for name, idx in self.LANDMARKS.items():
                    coords = self._get_landmark_coords(landmarks, idx)
                    visibility = landmarks.landmark[idx].visibility
                    joints[name] = {'coords': coords, 'visibility': visibility}
                
                # Calculate key angles
                if all(joints[j]['visibility'] > 0.5 for j in ['left_hip', 'left_knee', 'left_ankle']):
                    angles['left_knee'] = self._calculate_angle(
                        joints['left_hip']['coords'],
                        joints['left_knee']['coords'],
                        joints['left_ankle']['coords']
                    )
                if all(joints[j]['visibility'] > 0.5 for j in ['right_hip', 'right_knee', 'right_ankle']):
                    angles['right_knee'] = self._calculate_angle(
                        joints['right_hip']['coords'],
                        joints['right_knee']['coords'],
                        joints['right_ankle']['coords']
                    )
                if all(joints[j]['visibility'] > 0.5 for j in ['left_shoulder', 'left_elbow', 'left_wrist']):
                    angles['left_elbow'] = self._calculate_angle(
                        joints['left_shoulder']['coords'],
                        joints['left_elbow']['coords'],
                        joints['left_wrist']['coords']
                    )
                if all(joints[j]['visibility'] > 0.5 for j in ['right_shoulder', 'right_elbow', 'right_wrist']):
                    angles['right_elbow'] = self._calculate_angle(
                        joints['right_shoulder']['coords'],
                        joints['right_elbow']['coords'],
                        joints['right_wrist']['coords']
                    )
                
                # Draw skeleton with colors
                frame = self._draw_skeleton(frame, landmarks, angles, exercise, form_scores)
                
                # Draw ideal guides
                frame = self._draw_ideal_guide(frame, landmarks, exercise, angles)
            
            # Draw score overlay
            frame = self._draw_score_overlay(frame, form_scores, quality_score, exercise)
            
            out.write(frame)
            frame_count += 1
        
        cap.release()
        out.release()
        
        print(f"[PoseAnalyzer] Generated annotated video: {output_path} ({frame_count} frames)")
        return output_filename
    
    def _extract_pose_data(self, frame: np.ndarray) -> Optional[Dict[str, Any]]:
        """
        Extract pose landmarks from a single frame.
        
        Returns None if no pose detected.
        """
        # Convert BGR to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.pose.process(rgb_frame)
        
        if not results.pose_landmarks:
            return None
        
        landmarks = results.pose_landmarks
        
        # Extract key joint positions
        joints = {}
        for name, idx in self.LANDMARKS.items():
            coords = self._get_landmark_coords(landmarks, idx)
            visibility = landmarks.landmark[idx].visibility
            joints[name] = {
                'coords': coords,
                'visibility': visibility
            }
        
        # Calculate key angles
        angles = {}
        
        # Knee angles
        if all(joints[j]['visibility'] > 0.5 for j in ['left_hip', 'left_knee', 'left_ankle']):
            angles['left_knee'] = self._calculate_angle(
                joints['left_hip']['coords'],
                joints['left_knee']['coords'],
                joints['left_ankle']['coords']
            )
        
        if all(joints[j]['visibility'] > 0.5 for j in ['right_hip', 'right_knee', 'right_ankle']):
            angles['right_knee'] = self._calculate_angle(
                joints['right_hip']['coords'],
                joints['right_knee']['coords'],
                joints['right_ankle']['coords']
            )
        
        # Hip angles
        if all(joints[j]['visibility'] > 0.5 for j in ['left_shoulder', 'left_hip', 'left_knee']):
            angles['left_hip'] = self._calculate_angle(
                joints['left_shoulder']['coords'],
                joints['left_hip']['coords'],
                joints['left_knee']['coords']
            )
        
        if all(joints[j]['visibility'] > 0.5 for j in ['right_shoulder', 'right_hip', 'right_knee']):
            angles['right_hip'] = self._calculate_angle(
                joints['right_shoulder']['coords'],
                joints['right_hip']['coords'],
                joints['right_knee']['coords']
            )
        
        # Elbow angles
        if all(joints[j]['visibility'] > 0.5 for j in ['left_shoulder', 'left_elbow', 'left_wrist']):
            angles['left_elbow'] = self._calculate_angle(
                joints['left_shoulder']['coords'],
                joints['left_elbow']['coords'],
                joints['left_wrist']['coords']
            )
        
        if all(joints[j]['visibility'] > 0.5 for j in ['right_shoulder', 'right_elbow', 'right_wrist']):
            angles['right_elbow'] = self._calculate_angle(
                joints['right_shoulder']['coords'],
                joints['right_elbow']['coords'],
                joints['right_wrist']['coords']
            )
        
        # Shoulder angles (arm raise)
        if all(joints[j]['visibility'] > 0.5 for j in ['left_elbow', 'left_shoulder', 'left_hip']):
            angles['left_shoulder'] = self._calculate_angle(
                joints['left_elbow']['coords'],
                joints['left_shoulder']['coords'],
                joints['left_hip']['coords']
            )
        
        if all(joints[j]['visibility'] > 0.5 for j in ['right_elbow', 'right_shoulder', 'right_hip']):
            angles['right_shoulder'] = self._calculate_angle(
                joints['right_elbow']['coords'],
                joints['right_shoulder']['coords'],
                joints['right_hip']['coords']
            )
        
        # Spine alignment (shoulder-hip-knee line)
        if all(joints[j]['visibility'] > 0.5 for j in ['left_shoulder', 'left_hip', 'right_shoulder', 'right_hip']):
            mid_shoulder = (joints['left_shoulder']['coords'] + joints['right_shoulder']['coords']) / 2
            mid_hip = (joints['left_hip']['coords'] + joints['right_hip']['coords']) / 2
            
            # Vertical alignment (how vertical is the spine)
            spine_vector = mid_shoulder - mid_hip
            vertical = np.array([0, -1, 0])  # Y points down in image coords
            spine_angle = self._calculate_angle(
                mid_shoulder,
                mid_hip,
                mid_hip + vertical
            )
            angles['spine_vertical'] = spine_angle
        
        return {
            'joints': joints,
            'angles': angles,
            'landmarks': landmarks
        }
    
    def _detect_exercise(self, angle_history: List[Dict[str, float]]) -> Tuple[str, float]:
        """
        Detect exercise type based on joint angle patterns.
        
        Returns (exercise_name, confidence)
        """
        if not angle_history:
            return "unknown", 0.0
        
        # Analyze which joints are moving the most
        joint_variance = {}
        for joint in ['left_knee', 'right_knee', 'left_hip', 'right_hip', 
                      'left_elbow', 'right_elbow', 'left_shoulder', 'right_shoulder']:
            angles = [frame.get(joint, 0) for frame in angle_history if joint in frame]
            if len(angles) > 5:
                joint_variance[joint] = np.std(angles)
            else:
                joint_variance[joint] = 0
        
        # Get min/max knee angle to detect depth
        knee_angles = []
        for frame in angle_history:
            for k in ['left_knee', 'right_knee']:
                if k in frame:
                    knee_angles.append(frame[k])
        
        elbow_angles = []
        for frame in angle_history:
            for k in ['left_elbow', 'right_elbow']:
                if k in frame:
                    elbow_angles.append(frame[k])
        
        hip_angles = []
        for frame in angle_history:
            for k in ['left_hip', 'right_hip']:
                if k in frame:
                    hip_angles.append(frame[k])
        
        # Scoring for each exercise
        scores = {}
        
        # Squat: knees and hips move significantly, knees go below 120 degrees
        if knee_angles and hip_angles:
            knee_min = min(knee_angles)
            knee_range = max(knee_angles) - min(knee_angles)
            hip_range = max(hip_angles) - min(hip_angles)
            
            if knee_range > 20 and hip_range > 20 and knee_min < 130:
                scores['squat'] = min(100, knee_range + hip_range)
        
        # Pushup: elbows move, body stays horizontal
        if elbow_angles:
            elbow_range = max(elbow_angles) - min(elbow_angles)
            if elbow_range > 30:
                scores['pushup'] = elbow_range
        
        # Bicep curl: elbows move, shoulders stay still
        if elbow_angles:
            elbow_range = max(elbow_angles) - min(elbow_angles)
            shoulder_var = joint_variance.get('left_shoulder', 0) + joint_variance.get('right_shoulder', 0)
            if elbow_range > 40 and shoulder_var < 10:
                scores['bicep_curl'] = elbow_range
        
        # Shoulder press: elbows and shoulders move, arms go overhead
        if elbow_angles:
            elbow_range = max(elbow_angles) - min(elbow_angles)
            shoulder_var = joint_variance.get('left_shoulder', 0) + joint_variance.get('right_shoulder', 0)
            if elbow_range > 30 and shoulder_var > 10:
                scores['shoulder_press'] = elbow_range + shoulder_var
        
        # Deadlift: hips move a lot, knees less
        if hip_angles and knee_angles:
            hip_range = max(hip_angles) - min(hip_angles)
            knee_range = max(knee_angles) - min(knee_angles)
            if hip_range > 30 and hip_range > knee_range:
                scores['deadlift'] = hip_range
        
        # Lunge: asymmetric knee movement
        left_knee_angles = [f.get('left_knee', 0) for f in angle_history if 'left_knee' in f]
        right_knee_angles = [f.get('right_knee', 0) for f in angle_history if 'right_knee' in f]
        if left_knee_angles and right_knee_angles:
            left_range = max(left_knee_angles) - min(left_knee_angles) if left_knee_angles else 0
            right_range = max(right_knee_angles) - min(right_knee_angles) if right_knee_angles else 0
            asymmetry = abs(left_range - right_range)
            if asymmetry > 20 and max(left_range, right_range) > 30:
                scores['lunge'] = max(left_range, right_range)
        
        if not scores:
            return "unknown", 0.0
        
        best_exercise = max(scores, key=scores.get)
        confidence = min(95, scores[best_exercise]) / 100.0
        
        return best_exercise, confidence
    
    def _calculate_depth_score(self, angle_history: List[Dict], exercise: str) -> float:
        """Calculate depth score based on joint angles reaching full range."""
        if exercise in ['squat', 'lunge']:
            # Depth = how low the knee angle goes (lower is deeper)
            knee_angles = []
            for frame in angle_history:
                for k in ['left_knee', 'right_knee']:
                    if k in frame:
                        knee_angles.append(frame[k])
            
            if not knee_angles:
                return 50.0
            
            min_knee = min(knee_angles)
            
            # Perfect squat depth: 70-90 degrees
            # Shallow: > 120 degrees
            if min_knee <= 90:
                return 100.0
            elif min_knee <= 100:
                return 90.0
            elif min_knee <= 110:
                return 75.0
            elif min_knee <= 120:
                return 60.0
            elif min_knee <= 130:
                return 45.0
            else:
                return 30.0
        
        elif exercise in ['pushup']:
            elbow_angles = []
            for frame in angle_history:
                for k in ['left_elbow', 'right_elbow']:
                    if k in frame:
                        elbow_angles.append(frame[k])
            
            if not elbow_angles:
                return 50.0
            
            min_elbow = min(elbow_angles)
            
            if min_elbow <= 70:
                return 100.0
            elif min_elbow <= 90:
                return 80.0
            elif min_elbow <= 110:
                return 60.0
            else:
                return 40.0
        
        elif exercise in ['bicep_curl']:
            elbow_angles = []
            for frame in angle_history:
                for k in ['left_elbow', 'right_elbow']:
                    if k in frame:
                        elbow_angles.append(frame[k])
            
            if not elbow_angles:
                return 50.0
            
            min_elbow = min(elbow_angles)
            
            if min_elbow <= 40:
                return 100.0
            elif min_elbow <= 55:
                return 85.0
            elif min_elbow <= 70:
                return 70.0
            else:
                return 50.0
        
        return 60.0  # Default for other exercises
    
    def _calculate_alignment_score(self, pose_history: List[Dict]) -> float:
        """Calculate body alignment score based on spine angle."""
        spine_angles = []
        for frame in pose_history:
            if 'angles' in frame and 'spine_vertical' in frame['angles']:
                spine_angles.append(frame['angles']['spine_vertical'])
        
        if not spine_angles:
            return 50.0
        
        # Good alignment: spine stays within 10-20 degrees of vertical (during standing)
        # or consistent angle during movement
        avg_deviation = np.mean([abs(a - 180) for a in spine_angles])
        variance = np.std(spine_angles)
        
        # Lower deviation from vertical = better alignment
        if avg_deviation <= 15:
            alignment = 95.0
        elif avg_deviation <= 25:
            alignment = 80.0
        elif avg_deviation <= 35:
            alignment = 65.0
        else:
            alignment = 50.0
        
        # Penalize inconsistent alignment
        if variance > 15:
            alignment -= 15
        elif variance > 10:
            alignment -= 10
        
        return max(20.0, min(100.0, alignment))
    
    def _calculate_stability_score(self, pose_history: List[Dict]) -> float:
        """Calculate stability based on joint position variance."""
        if len(pose_history) < 5:
            return 50.0
        
        # Track hip position variance (good stability = hips don't wobble side to side)
        hip_x_positions = []
        hip_y_positions = []
        
        for frame in pose_history:
            if 'joints' in frame:
                joints = frame['joints']
                if 'left_hip' in joints and 'right_hip' in joints:
                    left_hip = joints['left_hip']['coords']
                    right_hip = joints['right_hip']['coords']
                    mid_hip = (left_hip + right_hip) / 2
                    hip_x_positions.append(mid_hip[0])
                    hip_y_positions.append(mid_hip[1])
        
        if len(hip_x_positions) < 5:
            return 50.0
        
        # Calculate lateral wobble (x-axis variance relative to movement)
        x_variance = np.std(hip_x_positions)
        
        # Good stability: low lateral variance
        if x_variance < 0.02:
            return 95.0
        elif x_variance < 0.03:
            return 85.0
        elif x_variance < 0.05:
            return 70.0
        elif x_variance < 0.08:
            return 55.0
        else:
            return 40.0
    
    def _calculate_tempo_score(self, angle_history: List[Dict], fps: float) -> float:
        """Calculate tempo score based on movement speed consistency."""
        if len(angle_history) < 10 or fps <= 0:
            return 50.0
        
        # Look at knee or elbow angle changes over time
        for joint in ['left_knee', 'right_knee', 'left_elbow', 'right_elbow']:
            angles = [f.get(joint) for f in angle_history if joint in f]
            if len(angles) > 10:
                break
        else:
            return 50.0
        
        # Calculate frame-to-frame angle change rate
        angle_speeds = []
        for i in range(1, len(angles)):
            speed = abs(angles[i] - angles[i-1])
            angle_speeds.append(speed)
        
        if not angle_speeds:
            return 50.0
        
        # Good tempo: consistent speed (low variance in speed)
        speed_variance = np.std(angle_speeds)
        avg_speed = np.mean(angle_speeds)
        
        # Coefficient of variation (lower is more consistent)
        if avg_speed > 0:
            cv = speed_variance / avg_speed
        else:
            cv = 0
        
        if cv < 0.3:
            return 95.0
        elif cv < 0.5:
            return 80.0
        elif cv < 0.7:
            return 65.0
        elif cv < 1.0:
            return 50.0
        else:
            return 35.0
    
    def _calculate_range_of_motion_score(self, angle_history: List[Dict], exercise: str) -> Tuple[float, float]:
        """Calculate range of motion based on joint angle range achieved."""
        # Get the primary joint angles for this exercise type
        if exercise in ['squat', 'lunge', 'deadlift']:
            joint_keys = ['left_knee', 'right_knee', 'left_hip', 'right_hip']
        elif exercise in ['pushup', 'bicep_curl', 'shoulder_press', 'row']:
            joint_keys = ['left_elbow', 'right_elbow']
        else:
            joint_keys = ['left_knee', 'right_knee', 'left_elbow', 'right_elbow']
        
        ranges = []
        for joint in joint_keys:
            angles = [f.get(joint) for f in angle_history if joint in f]
            if len(angles) > 5:
                joint_range = max(angles) - min(angles)
                ranges.append(joint_range)
        
        if not ranges:
            return (50.0, 0.0)
        
        avg_range = np.mean(ranges)
        
        # Good ROM: > 60 degrees of movement for most exercises
        if avg_range >= 70:
            return 95.0, avg_range
        elif avg_range >= 55:
            return 85.0, avg_range
        elif avg_range >= 40:
            return 70.0, avg_range
        elif avg_range >= 25:
            return 55.0, avg_range
        else:
            return 35.0, avg_range
    
    def _generate_detailed_feedback(
        self,
        quality_score: float,
        form_scores: Dict[str, float],
        exercise: str,
        angle_history: List[Dict],
        pose_history: List[Dict],
        metrics: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate detailed, specific feedback with actual measured values."""
        feedback = []
        
        # Extract detailed metrics for feedback
        knee_angles = {'left': [], 'right': []}
        elbow_angles = {'left': [], 'right': []}
        hip_angles = {'left': [], 'right': []}
        
        for frame in angle_history:
            for side in ['left', 'right']:
                if f'{side}_knee' in frame:
                    knee_angles[side].append(frame[f'{side}_knee'])
                if f'{side}_elbow' in frame:
                    elbow_angles[side].append(frame[f'{side}_elbow'])
                if f'{side}_hip' in frame:
                    hip_angles[side].append(frame[f'{side}_hip'])
        
        # Calculate key metrics
        min_knee_left = min(knee_angles['left']) if knee_angles['left'] else None
        min_knee_right = min(knee_angles['right']) if knee_angles['right'] else None
        min_elbow_left = min(elbow_angles['left']) if elbow_angles['left'] else None
        min_elbow_right = min(elbow_angles['right']) if elbow_angles['right'] else None
        
        # Overall feedback with score
        if quality_score >= 80:
            overall_text = f"Excellent {exercise.replace('_', ' ')} form! Your overall score is {quality_score:.0f}/100. Great work maintaining good technique throughout the movement."
            fb_type = "positive"
        elif quality_score >= 60:
            overall_text = f"Good {exercise.replace('_', ' ')}! Your score is {quality_score:.0f}/100. You're on the right track - see the specific tips below to improve further."
            fb_type = "encouragement"
        else:
            overall_text = f"Your {exercise.replace('_', ' ')} needs work. Current score: {quality_score:.0f}/100. Focus on the corrections below to improve your form and prevent injury."
            fb_type = "correction"
        
        feedback.append({
            "id": str(uuid.uuid4()),
            "type": fb_type,
            "category": "overall",
            "text": overall_text,
            "score": quality_score,
            "severity": 1 if quality_score >= 80 else (2 if quality_score >= 60 else 3)
        })
        
        # DEPTH feedback with actual angles
        depth_score = form_scores.get('depth', 50)
        if exercise in ['squat', 'lunge']:
            if min_knee_left and min_knee_right:
                avg_min_knee = (min_knee_left + min_knee_right) / 2
                knee_diff = abs(min_knee_left - min_knee_right)
                
                if depth_score >= 80:
                    text = f"Great depth! Your knees bent to {avg_min_knee:.0f}° at the lowest point, which is excellent for muscle activation."
                    if knee_diff > 10:
                        text += f" However, there's a {knee_diff:.0f}° difference between your left ({min_knee_left:.0f}°) and right ({min_knee_right:.0f}°) knee - try to keep them more even."
                elif depth_score >= 50:
                    text = f"Your depth reached {avg_min_knee:.0f}°. Try to get below 90° for better muscle engagement. "
                    if avg_min_knee > 100:
                        text += "Focus on sitting back into your heels and pushing your hips back."
                else:
                    text = f"Depth is limited at {avg_min_knee:.0f}°. Work on hip and ankle mobility to achieve deeper positions. Try box squats to build confidence at lower depths."
                
                feedback.append({
                    "id": str(uuid.uuid4()),
                    "type": "positive" if depth_score >= 80 else ("encouragement" if depth_score >= 50 else "correction"),
                    "category": "depth",
                    "text": text,
                    "score": depth_score,
                    "severity": 1 if depth_score >= 80 else (2 if depth_score >= 50 else 3),
                    "metrics": {"min_knee_angle": avg_min_knee, "knee_asymmetry": knee_diff}
                })
        
        elif exercise in ['pushup']:
            if min_elbow_left and min_elbow_right:
                avg_min_elbow = (min_elbow_left + min_elbow_right) / 2
                
                if depth_score >= 80:
                    text = f"Excellent pushup depth! Elbows reached {avg_min_elbow:.0f}° - great range for chest and tricep activation."
                elif depth_score >= 50:
                    text = f"Your elbows bent to {avg_min_elbow:.0f}°. Try to get closer to 90° or below for full chest engagement."
                else:
                    text = f"Limited depth at {avg_min_elbow:.0f}°. Lower your chest closer to the ground - aim for elbows at 90° or less."
                
                feedback.append({
                    "id": str(uuid.uuid4()),
                    "type": "positive" if depth_score >= 80 else ("encouragement" if depth_score >= 50 else "correction"),
                    "category": "depth",
                    "text": text,
                    "score": depth_score,
                    "severity": 1 if depth_score >= 80 else (2 if depth_score >= 50 else 3)
                })
        
        # ALIGNMENT feedback
        alignment_score = form_scores.get('alignment', 50)
        spine_angles = [f['angles'].get('spine_vertical', 180) for f in pose_history if 'angles' in f and 'spine_vertical' in f['angles']]
        
        if spine_angles:
            avg_spine = np.mean(spine_angles)
            spine_variance = np.std(spine_angles)
            max_deviation = max(abs(a - 180) for a in spine_angles)
            
            if alignment_score >= 80:
                text = f"Excellent alignment! Your spine stayed within {max_deviation:.0f}° of vertical throughout the movement."
            elif alignment_score >= 50:
                text = f"Your spine deviated up to {max_deviation:.0f}° from vertical. Focus on keeping your core tight and maintaining a neutral spine position."
                if spine_variance > 10:
                    text += f" Your alignment also varied by {spine_variance:.0f}° - try to keep it more consistent."
            else:
                text = f"Alignment needs work - your spine deviated {max_deviation:.0f}° from neutral. Engage your core before starting the movement and imagine a straight line from head to hips."
            
            feedback.append({
                "id": str(uuid.uuid4()),
                "type": "positive" if alignment_score >= 80 else ("encouragement" if alignment_score >= 50 else "correction"),
                "category": "alignment",
                "text": text,
                "score": alignment_score,
                "severity": 1 if alignment_score >= 80 else (2 if alignment_score >= 50 else 3),
                "metrics": {"max_spine_deviation": max_deviation, "spine_variance": spine_variance}
            })
        
        # STABILITY feedback
        stability_score = form_scores.get('stability', 50)
        if stability_score >= 80:
            text = "Very stable movement! Your body stayed controlled with minimal side-to-side wobble."
        elif stability_score >= 50:
            text = "Some instability detected during your movement. Focus on bracing your core and moving more slowly through the exercise."
        else:
            text = "Your movement shows significant wobble. Try reducing the weight/difficulty and focus on controlled, deliberate movements. Consider doing single-leg balance exercises to improve stability."
        
        feedback.append({
            "id": str(uuid.uuid4()),
            "type": "positive" if stability_score >= 80 else ("encouragement" if stability_score >= 50 else "correction"),
            "category": "stability",
            "text": text,
            "score": stability_score,
            "severity": 1 if stability_score >= 80 else (2 if stability_score >= 50 else 3)
        })
        
        # TEMPO feedback
        tempo_score = form_scores.get('tempo', 50)
        if tempo_score >= 80:
            text = "Great tempo! Your movement speed was consistent and controlled throughout each rep."
        elif tempo_score >= 50:
            text = "Your tempo varied during the movement. Try counting '2 seconds down, 1 second pause, 2 seconds up' to maintain consistency."
        else:
            text = "Movement speed is inconsistent - you may be rushing parts of the exercise. Slow down and focus on a controlled 2-1-2 tempo (2 seconds eccentric, 1 second pause, 2 seconds concentric)."
        
        feedback.append({
            "id": str(uuid.uuid4()),
            "type": "positive" if tempo_score >= 80 else ("encouragement" if tempo_score >= 50 else "correction"),
            "category": "tempo",
            "text": text,
            "score": tempo_score,
            "severity": 1 if tempo_score >= 80 else (2 if tempo_score >= 50 else 3)
        })
        
        # RANGE OF MOTION feedback
        rom_score = form_scores.get('range_of_motion', 50)
        rom_value = metrics.get('rom_range', 0)
        
        if rom_score >= 80:
            text = f"Full range of motion achieved! Your joints moved through {rom_value:.0f}° of motion, maximizing muscle engagement."
        elif rom_score >= 50:
            text = f"Your range of motion was {rom_value:.0f}°. Try to extend both ends of the movement - go deeper at the bottom and fully extend at the top."
        else:
            text = f"Limited range at {rom_value:.0f}°. Work on flexibility and mobility. Try dynamic stretching before your workout and static stretching after."
        
        feedback.append({
            "id": str(uuid.uuid4()),
            "type": "positive" if rom_score >= 80 else ("encouragement" if rom_score >= 50 else "correction"),
            "category": "range_of_motion",
            "text": text,
            "score": rom_score,
            "severity": 1 if rom_score >= 80 else (2 if rom_score >= 50 else 3),
            "metrics": {"range_degrees": rom_value}
        })
        
        # ASYMMETRY check for bilateral exercises
        if exercise in ['squat', 'deadlift', 'shoulder_press', 'row']:
            asymmetries = []
            
            if knee_angles['left'] and knee_angles['right']:
                left_range = max(knee_angles['left']) - min(knee_angles['left'])
                right_range = max(knee_angles['right']) - min(knee_angles['right'])
                knee_asym = abs(left_range - right_range)
                if knee_asym > 15:
                    asymmetries.append(f"knee movement ({knee_asym:.0f}° difference)")
            
            if elbow_angles['left'] and elbow_angles['right']:
                left_range = max(elbow_angles['left']) - min(elbow_angles['left'])
                right_range = max(elbow_angles['right']) - min(elbow_angles['right'])
                elbow_asym = abs(left_range - right_range)
                if elbow_asym > 15:
                    asymmetries.append(f"arm movement ({elbow_asym:.0f}° difference)")
            
            if asymmetries:
                feedback.append({
                    "id": str(uuid.uuid4()),
                    "type": "correction",
                    "category": "asymmetry",
                    "text": f"Asymmetry detected in your {', '.join(asymmetries)}. This could indicate a strength imbalance or mobility restriction. Consider adding single-leg/arm exercises to address this.",
                    "score": 50,
                    "severity": 2
                })
        
        # Sort by severity (most important corrections first)
        feedback.sort(key=lambda x: x["severity"], reverse=True)
        
        return feedback
    
    async def analyze_video(
        self,
        video_path: str,
        exercise_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Analyze a workout video using pose detection.
        
        Args:
            video_path: Path to video file
            exercise_type: Optional exercise type hint
            
        Returns:
            Analysis results with scores and feedback
        """
        start_time = datetime.utcnow()
        
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Could not open video: {video_path}")
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        pose_history = []
        angle_history = []
        frames_with_pose = 0
        frame_count = 0
        
        # Sample every N frames to speed up processing
        sample_rate = max(1, int(fps / 10))  # Analyze ~10 frames per second
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            frame_count += 1
            
            # Skip frames based on sample rate
            if frame_count % sample_rate != 0:
                continue
            
            pose_data = self._extract_pose_data(frame)
            
            if pose_data:
                frames_with_pose += 1
                pose_history.append(pose_data)
                angle_history.append(pose_data['angles'])
        
        cap.release()
        
        # Check if we detected a person
        detection_rate = frames_with_pose / max(1, frame_count // sample_rate)
        
        if detection_rate < 0.2:
            # No person detected in most frames
            return {
                "analysis_id": str(uuid.uuid4()),
                "timestamp": datetime.utcnow().isoformat(),
                "error": "no_person_detected",
                "quality_score": 0,
                "detected_exercise": "none",
                "detection_confidence": 0,
                "form_scores": {
                    "depth": 0,
                    "alignment": 0,
                    "stability": 0,
                    "tempo": 0,
                    "range_of_motion": 0
                },
                "feedback": [{
                    "id": str(uuid.uuid4()),
                    "type": "error",
                    "category": "detection",
                    "text": "No person detected in the video. Please ensure you are fully visible in the frame.",
                    "score": 0,
                    "severity": 4
                }],
                "metrics": {
                    "video_fps": fps,
                    "total_frames": total_frames,
                    "frames_analyzed": frame_count // sample_rate,
                    "frames_with_pose": frames_with_pose,
                    "detection_rate": round(detection_rate * 100, 1),
                    "processing_time_seconds": round((datetime.utcnow() - start_time).total_seconds(), 3)
                }
            }
        
        # Detect exercise type
        detected_exercise, confidence = self._detect_exercise(angle_history)
        
        if exercise_type:
            detected_exercise = exercise_type.lower().replace(" ", "_")
        
        # Calculate form scores
        depth_score = self._calculate_depth_score(angle_history, detected_exercise)
        alignment_score = self._calculate_alignment_score(pose_history)
        stability_score = self._calculate_stability_score(pose_history)
        tempo_score = self._calculate_tempo_score(angle_history, fps)
        rom_result = self._calculate_range_of_motion_score(angle_history, detected_exercise)
        rom_score = rom_result[0] if isinstance(rom_result, tuple) else rom_result
        rom_range = rom_result[1] if isinstance(rom_result, tuple) else 0
        
        form_scores = {
            "depth": round(depth_score, 1),
            "alignment": round(alignment_score, 1),
            "stability": round(stability_score, 1),
            "tempo": round(tempo_score, 1),
            "range_of_motion": round(rom_score, 1)
        }
        
        # Overall quality score (weighted average)
        quality_score = (
            depth_score * 0.25 +
            alignment_score * 0.20 +
            stability_score * 0.20 +
            tempo_score * 0.15 +
            rom_score * 0.20
        )
        
        # Generate detailed feedback with actual measurements
        feedback = self._generate_detailed_feedback(
            quality_score, 
            form_scores, 
            detected_exercise,
            angle_history,
            pose_history,
            {"rom_range": rom_range}
        )
        
        # Generate annotated video with pose overlay
        annotated_video = self._generate_annotated_video(
            video_path, 
            detected_exercise, 
            form_scores, 
            quality_score
        )
        
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        
        analysis_id = str(uuid.uuid4())
        
        return {
            "analysis_id": analysis_id,
            "timestamp": datetime.utcnow().isoformat(),
            "quality_score": round(quality_score, 1),
            "detected_exercise": detected_exercise,
            "detection_confidence": round(confidence * 100, 1),
            "form_scores": form_scores,
            "feedback": feedback,
            "annotated_video": annotated_video,
            "annotated_video_url": f"/api/v1/video/playback/{annotated_video}" if annotated_video else None,
            "metrics": {
                "video_fps": fps,
                "total_frames": total_frames,
                "frames_analyzed": frame_count // sample_rate,
                "frames_with_pose": frames_with_pose,
                "detection_rate": round(detection_rate * 100, 1),
                "processing_time_seconds": round(processing_time, 3)
            }
        }
    
    async def analyze_video_bytes(
        self,
        video_bytes: bytes,
        filename: str,
        exercise_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """Analyze video from bytes."""
        import tempfile
        import os
        
        # Save to temporary file
        suffix = os.path.splitext(filename)[1] or '.mp4'
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(video_bytes)
            tmp_path = tmp.name
        
        try:
            result = await self.analyze_video(tmp_path, exercise_type)
        finally:
            os.unlink(tmp_path)
        
        return result


# Global analyzer instance
_analyzer: Optional[PoseAnalyzer] = None


def get_pose_analyzer() -> PoseAnalyzer:
    """Get or create the global PoseAnalyzer instance."""
    global _analyzer
    if _analyzer is None:
        _analyzer = PoseAnalyzer()
    return _analyzer
