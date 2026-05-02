# CLAUDE.md

Do not forget that classes, methods, variables and everything should be portuguese from Portugal. And do not add comments but do not remove already existing ones either.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language & Style

- All identifiers (classes, variables, methods, fields) in **Portuguese from Portugal** — not Brazilian Portuguese (e.g. `utilizador` not `usuário`, `guardar` not `salvar`)
- No comments in code
- Simple code — avoid abstractions unless genuinely required

## Commands

```bash
flutter pub get          # fetch dependencies
flutter run              # run debug on connected device/emulator
flutter analyze          # static analysis / lint
flutter test             # run widget tests
flutter build apk        # build Android APK
flutter build appbundle  # build Android App Bundle
```

## Architecture

Single-screen Flutter app managing restaurant orders for "Casa da Avó".

```
lib/
├── main.dart           # MyApp — MaterialApp, no debug banner
├── models/
│   └── pedido.dart     # Pedido model — toJson/fromJson for SharedPreferences persistence
└── pages/
    └── home.dart       # All UI and business logic
```

`HomePage` is a single `StatefulWidget` owning `_listaDePedidos: List<Pedido>`. State managed with pure `setState` — no external state management. Two bottom tabs:
- Tab 0: Order form (cliente, prato, bebida, sobremesa) with `UpperCaseFirstLetterFormatter`
- Tab 1: ListView of orders with per-item delete

Persistence: `SharedPreferences` key `'meus_pedidos'` — JSON-encoded list. `_guardarDados()` writes on every mutation; `_carregarDados()` reads in `initState()`.

`Pedido.dataCriacao` is a `DateTime` stored as ISO 8601. Old records without the field default to `DateTime.now()` on load. Relative time displayed via `_tempoRelativo()` in PT-PT (e.g. "há 2 minutos").

All `TextEditingController`s disposed in `dispose()`.
