from __future__ import annotations

import operator
from abc import ABC, abstractmethod
from typing import Dict, Iterable, List, Optional, Tuple

from app.ml.rules.findings import Finding, Severity

OPERATORS = {
    "<": operator.lt,
    "<=": operator.le,
    ">": operator.gt,
    ">=": operator.ge,
}


class Rule(ABC):
    fault: str

    @abstractmethod
    def evaluate(self, features: Dict[str, float], rep_index: Optional[int] = None) -> Optional[Finding]:
        ...

    def required_features(self) -> Tuple[str, ...]:
        return ()


class ThresholdRule(Rule):
    def __init__(
        self,
        fault: str,
        feature: str,
        op: str,
        threshold: float,
        message: str,
        severity: Severity = Severity.WARNING,
        joints: Iterable[str] = (),
    ) -> None:
        if op not in OPERATORS:
            raise ValueError(f"op must be one of {sorted(OPERATORS)}")
        self.fault = fault
        self.feature = feature
        self.op = op
        self.threshold = threshold
        self.message = message
        self.severity = severity
        self.joints = tuple(joints)

    def required_features(self) -> Tuple[str, ...]:
        return (self.feature,)

    def evaluate(self, features: Dict[str, float], rep_index: Optional[int] = None) -> Optional[Finding]:
        value = features[self.feature]
        if not OPERATORS[self.op](value, self.threshold):
            return None
        return Finding(
            fault=self.fault,
            message=self.message,
            severity=self.severity,
            source="rule",
            rep_index=rep_index,
            joints=self.joints,
            evidence={"feature": self.feature, "value": value, "op": self.op, "threshold": self.threshold},
        )


class GuardedRule(Rule):
    def __init__(self, rule: Rule, feature: str, op: str, threshold: float) -> None:
        if op not in OPERATORS:
            raise ValueError(f"op must be one of {sorted(OPERATORS)}")
        self.rule = rule
        self.fault = rule.fault
        self.feature = feature
        self.op = op
        self.threshold = threshold

    def required_features(self) -> Tuple[str, ...]:
        return (self.feature,) + tuple(self.rule.required_features())

    def evaluate(self, features: Dict[str, float], rep_index: Optional[int] = None) -> Optional[Finding]:
        if not OPERATORS[self.op](features[self.feature], self.threshold):
            return None
        return self.rule.evaluate(features, rep_index)


class RuleEngine:
    def __init__(self, rules: Iterable[Rule]) -> None:
        self.rules: List[Rule] = list(rules)

    def validate(self, feature_names: Iterable[str]) -> None:
        available = set(feature_names)
        missing = sorted({f for r in self.rules for f in r.required_features()} - available)
        if missing:
            raise ValueError(f"rules reference unknown features: {missing}")

    def evaluate(self, features: Dict[str, float], rep_index: Optional[int] = None) -> List[Finding]:
        findings = []
        for rule in self.rules:
            finding = rule.evaluate(features, rep_index)
            if finding is not None:
                findings.append(finding)
        return findings
