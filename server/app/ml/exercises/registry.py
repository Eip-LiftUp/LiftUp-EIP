from __future__ import annotations

import importlib
import pkgutil
from typing import Dict, List, Type

from app.ml.exercises.base import ExerciseModule

_REGISTRY: Dict[str, ExerciseModule] = {}

_INTERNAL_MODULES = {"base", "registry"}


def register_exercise(cls: Type[ExerciseModule]) -> Type[ExerciseModule]:
    instance = cls()
    instance.validate()
    if instance.name in _REGISTRY and type(_REGISTRY[instance.name]) is not cls:
        raise ValueError(f"exercise '{instance.name}' is already registered")
    _REGISTRY[instance.name] = instance
    return cls


def unregister_exercise(name: str) -> None:
    _REGISTRY.pop(name, None)


def get_exercise(name: str) -> ExerciseModule:
    try:
        return _REGISTRY[name]
    except KeyError:
        raise KeyError(f"unknown exercise '{name}'; available: {available_exercises()}") from None


def available_exercises() -> List[str]:
    return sorted(_REGISTRY)


def load_builtin_exercises() -> List[str]:
    package = importlib.import_module("app.ml.exercises")
    for info in pkgutil.iter_modules(package.__path__):
        if info.name not in _INTERNAL_MODULES and not info.name.startswith("_"):
            importlib.import_module(f"app.ml.exercises.{info.name}")
    return available_exercises()
