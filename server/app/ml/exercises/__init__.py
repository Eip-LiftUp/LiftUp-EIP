from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.registry import (
    register_exercise,
    unregister_exercise,
    get_exercise,
    available_exercises,
    load_builtin_exercises,
)

__all__ = [
    "ExerciseModule",
    "FaultSpec",
    "register_exercise",
    "unregister_exercise",
    "get_exercise",
    "available_exercises",
    "load_builtin_exercises",
]
