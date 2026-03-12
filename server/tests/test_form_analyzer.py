"""
Tests for form analysis service
"""

import pytest
from app.services.form_analyzer import FormAnalyzer
from app.models.schemas import KeyPoint


@pytest.fixture
def form_analyzer():
    """Fixture for form analyzer"""
    return FormAnalyzer()


def test_form_analyzer_initialization(form_analyzer):
    """Test form analyzer initializes correctly"""
    assert form_analyzer is not None
    assert len(form_analyzer.supported_exercises) > 0


def test_get_supported_exercises(form_analyzer):
    """Test getting supported exercises"""
    exercises = form_analyzer.get_supported_exercises()
    assert isinstance(exercises, list)
    assert "squat" in exercises
    assert "deadlift" in exercises


@pytest.mark.asyncio
async def test_get_exercise_guidelines(form_analyzer):
    """Test getting exercise guidelines"""
    guidelines = await form_analyzer.get_exercise_guidelines("squat")
    assert "description" in guidelines
    assert "key_points" in guidelines
    assert "common_mistakes" in guidelines
    assert "safety_tips" in guidelines


@pytest.mark.asyncio
async def test_get_invalid_exercise_guidelines(form_analyzer):
    """Test getting guidelines for invalid exercise"""
    with pytest.raises(ValueError):
        await form_analyzer.get_exercise_guidelines("invalid_exercise")


@pytest.mark.asyncio
async def test_analyze_form_mock(form_analyzer):
    """Test mock form analysis"""
    # Create mock keypoints
    mock_keypoints = [[
        KeyPoint(name="left_shoulder", x=0.3, y=0.4, confidence=0.9, visible=True),
        KeyPoint(name="right_shoulder", x=0.7, y=0.4, confidence=0.9, visible=True),
    ]]
    
    result = await form_analyzer.analyze_form(
        exercise_type="squat",
        keypoints=mock_keypoints
    )
    
    assert "comments" in result
    assert "overall_score" in result
    assert "metrics" in result
    assert isinstance(result["comments"], list)
    assert result["overall_score"] >= 0


# TODO: Add more tests for actual form analysis algorithms
