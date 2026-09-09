extends Node
## AgentFactoryHolder — TEST-ONLY object whose method is used as an explicit
## agent_factory Callable. Preload it (AL-001). A Node so the test can free it,
## invalidating `Callable(holder, "make_agent")`, to prove an explicit factory
## that drifts invalid fails closed with NO default-agent substitution
## (V03 F-M19-STRICT-002.B).

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

func make_agent():
	return ScrubbotAgent.new()
