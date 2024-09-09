# Pride

[![hex.pm](https://img.shields.io/hexpm/v/pride)](https://hex.pm/packages/pride)
[hexdocs](https://hexdocs.pm/pride)

Provides a prefixed UUIDv7 data type for Ecto, and related helpers

Originally based on examples by Dan Schultzer at https://danschultzer.com/posts/prefixed-base62-uuidv7-object-ids-with-ecto

## Installation

If you want to use a Rust implementation of UUIDv7 (powered by https://hexdocs.pm/uuidv7)
```elixir
{:pride, git: "https://github.com/bonfire-networks/pride", branch: "main"},
{:uuidv7, "~> 0.2"},
```
Or an Elixir implementation (powered by https://hexdocs.pm/uniq), : 
```elixir
{:pride, git: "https://github.com/bonfire-networks/pride", branch: "main"},
{:uniq, "~> 0.6"},
```
and include this in config: `config :pride, use_rust: false`

## Copyright and License

Copyright (c) 2024 Bonfire contributors
Copyright (c) 2023 Dan Schultzer

Licensed under the terms of the MIT License.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
