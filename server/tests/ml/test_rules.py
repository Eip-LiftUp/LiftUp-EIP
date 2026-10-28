import pytest

from app.ml.rules import ThresholdRule, GuardedRule, RuleEngine, Severity


def make_rule(**kw):
    defaults = dict(fault="shallow", feature="knee_min", op=">", threshold=100.0,
                    message="Go deeper", joints=("left_knee",))
    defaults.update(kw)
    return ThresholdRule(**defaults)


def test_threshold_rule_triggers_with_evidence():
    finding = make_rule().evaluate({"knee_min": 120.0}, rep_index=2)
    assert finding.fault == "shallow" and finding.source == "rule" and finding.rep_index == 2
    assert finding.evidence["value"] == 120.0
    d = finding.to_dict()
    assert d["severity"] == "warning" and d["joints"] == ["left_knee"]


def test_threshold_rule_silent_when_ok_and_bad_op():
    assert make_rule().evaluate({"knee_min": 90.0}) is None
    with pytest.raises(ValueError):
        make_rule(op="==")


def test_engine_collects_and_validates():
    engine = RuleEngine([make_rule(), make_rule(fault="lean", feature="torso_max", op=">=",
                                                threshold=45, severity=Severity.CRITICAL)])
    out = engine.evaluate({"knee_min": 120, "torso_max": 50})
    assert [f.fault for f in out] == ["shallow", "lean"]
    engine.validate(["knee_min", "torso_max"])
    with pytest.raises(ValueError, match="torso_max"):
        engine.validate(["knee_min"])


def test_guarded_rule_only_runs_when_guard_holds():
    rule = GuardedRule(make_rule(), "view", ">=", 0.5)
    assert rule.fault == "shallow"
    assert rule.required_features() == ("view", "knee_min")
    assert rule.evaluate({"view": 0.2, "knee_min": 150}) is None
    assert rule.evaluate({"view": 0.8, "knee_min": 150}).fault == "shallow"
    assert rule.evaluate({"view": 0.8, "knee_min": 90}) is None
    with pytest.raises(ValueError):
        GuardedRule(make_rule(), "view", "!=", 0)
