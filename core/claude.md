<!-- Claude-only wrapper. Codex and Gemini point straight at agents.md;
     Claude needs explicit top-level @imports here because transitive
     @imports inside an imported file are unreliable in CLAUDE.md. -->

@./agents.md
@./primitives/personas.md
@./primitives/tools.md
@./primitives/coordination.md
