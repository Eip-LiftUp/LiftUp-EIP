from __future__ import annotations

from dataclasses import dataclass, field, asdict
from enum import Enum
from typing import Any, Dict, Optional, Tuple


class Severity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


@dataclass(frozen=True)
class Finding:
    fault: str
    message: str
    severity: Severity
    source: str
    rep_index: Optional[int] = None
    confidence: float = 1.0
    joints: Tuple[str, ...] = ()
    evidence: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        out = asdict(self)
        out["severity"] = self.severity.value
        out["joints"] = list(self.joints)
        return out
