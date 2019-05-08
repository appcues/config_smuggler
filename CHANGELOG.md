# Changelog

## 0.7.2

Use `persistent: true` when persisting env with `Application.put_env/3`.

## 0.7.1

Made optional Poison dep more permissive.

## 0.7.0

Added `mix smuggle encode` task.  Fixed handling of config values
that aren't keyword lists but look almost like them.

## 0.6.0

`t:error_reason` is no longer string-typed, instead being one of
`:bad_input`, `:bad_key`, `:bad_value`, or `:load_error`.

Test coverage improved.

## 0.5.0

First release, consisting of `apply/1`, `decode/1`, `encode/1`,
`encode_file/1`, and `encode_statement/1`.
