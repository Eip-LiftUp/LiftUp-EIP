"""
Tests for pose estimation service
"""

import pytest
from app.services.pose_estimator import PoseEstimator


@pytest.fixture
def pose_estimator():
    """Fixture for pose estimator"""
    return PoseEstimator()


def test_pose_estimator_initialization(pose_estimator):
    """Test pose estimator initializes correctly"""
    assert pose_estimator is not None
    assert pose_estimator.model_version == "0.1.0"
    assert len(pose_estimator.keypoint_names) == 17


def test_get_keypoint_names(pose_estimator):
    """Test getting keypoint names"""
    names = pose_estimator.get_keypoint_names()
    assert isinstance(names, list)
    assert "nose" in names
    assert "left_shoulder" in names
    assert "right_knee" in names


@pytest.mark.asyncio
async def test_estimate_pose_mock(pose_estimator):
    """Test mock pose estimation"""
    # Create mock image data
    image_data = b"fake_image_data"
    
    # This will fail with current implementation but shows the test structure
    # Uncomment when actual implementation is ready
    # result = await pose_estimator.estimate_pose(image_data)
    # assert "keypoints" in result
    # assert "confidence" in result
    # assert len(result["keypoints"]) > 0


# TODO: Add more tests when real ML model is integrated
