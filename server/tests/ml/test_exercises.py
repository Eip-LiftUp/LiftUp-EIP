import pytest

from app.ml.exercises import (
    register_exercise,
    unregister_exercise,
    get_exercise,
    available_exercises,
    load_builtin_exercises,
)
from app.ml.rules import ThresholdRule
from tests.ml.fake_exercise import FakeSquat


@pytest.fixture
def registered():
    register_exercise(FakeSquat)
    yield get_exercise("test_squat")
    unregister_exercise("test_squat")


def test_register_and_lookup(registered):
    assert "test_squat" in available_exercises()
    assert registered.fault_names == ["shallow", "forward_lean"]
    assert registered.fault("forward_lean").severity.value == "critical"
    assert "knee_l_min" in registered.features.names
    with pytest.raises(KeyError):
        registered.fault("nope")


def test_reregister_same_class_is_idempotent(registered):
    register_exercise(FakeSquat)
    assert available_exercises().count("test_squat") == 1


def test_name_clash_rejected(registered):
    class Other(FakeSquat):
        pass
    with pytest.raises(ValueError, match="already registered"):
        register_exercise(Other)


def test_unknown_exercise_message():
    with pytest.raises(KeyError, match="unknown exercise"):
        get_exercise("does_not_exist")


def test_validation_catches_bad_definitions():
    class NoName(FakeSquat):
        name = ""

    class BadFeature(FakeSquat):
        name = "bad_feature"

        def build_rules(self):
            return [ThresholdRule("shallow", "typo_feature", ">", 1, "x")]

    class BadFault(FakeSquat):
        name = "bad_fault"

        def build_rules(self):
            return [ThresholdRule("undeclared", "knee_l_min", ">", 1, "x")]

    for cls in (NoName, BadFeature, BadFault):
        with pytest.raises(ValueError):
            register_exercise(cls)


def test_load_builtin_exercises_runs():
    assert isinstance(load_builtin_exercises(), list)
