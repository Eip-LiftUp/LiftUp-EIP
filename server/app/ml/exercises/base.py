from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from functools import cached_property
from typing import List, Tuple

import numpy as np

from app.ml.features import FeatureSet
from app.ml.pose import PoseSequence
from app.ml.preprocessing import PreprocessConfig
from app.ml.rules import Rule, RuleEngine, Severity
from app.ml.segmentation import SegmentationConfig


@dataclass(frozen=True)
class FaultSpec:
    name: str
    description: str
    message: str
    severity: Severity = Severity.WARNING
    joints: Tuple[str, ...] = ()


class ExerciseModule(ABC):
    name: str = ""
    display_name: str = ""
    preprocess_config: PreprocessConfig = PreprocessConfig()
    segmentation_config: SegmentationConfig = SegmentationConfig()

    @abstractmethod
    def primary_signal(self, seq: PoseSequence) -> np.ndarray:
        ...

    @abstractmethod
    def build_features(self) -> FeatureSet:
        ...

    def build_faults(self) -> List[FaultSpec]:
        return []

    def build_rules(self) -> List[Rule]:
        return []

    @cached_property
    def features(self) -> FeatureSet:
        return self.build_features()

    @cached_property
    def faults(self) -> List[FaultSpec]:
        return self.build_faults()

    @cached_property
    def rule_engine(self) -> RuleEngine:
        return RuleEngine(self.build_rules())

    @property
    def fault_names(self) -> List[str]:
        return [f.name for f in self.faults]

    def fault(self, name: str) -> FaultSpec:
        for f in self.faults:
            if f.name == name:
                return f
        raise KeyError(f"exercise '{self.name}' has no fault '{name}'")

    def validate(self) -> None:
        if not self.name:
            raise ValueError(f"{type(self).__name__} must define a non-empty 'name'")
        if len(set(self.fault_names)) != len(self.fault_names):
            raise ValueError(f"exercise '{self.name}' declares duplicate faults")
        self.rule_engine.validate(self.features.names)
        unknown = sorted({r.fault for r in self.rule_engine.rules} - set(self.fault_names))
        if unknown:
            raise ValueError(f"exercise '{self.name}' rules use undeclared faults: {unknown}")
