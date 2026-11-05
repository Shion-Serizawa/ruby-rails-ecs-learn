# ADR-0004: テストは RSpec + FactoryBot

- 状態: 採用
- 日付: 2026-11-04

## 背景

Rails の標準は Minitest + fixtures。どちらを使うか決める必要があった。

## 決定

RSpec (rspec-rails) + FactoryBot + shoulda-matchers + Capybara。

## 検討した他の案

| 案 | 採用しなかった理由 |
| --- | --- |
| Minitest + fixtures (Rails 標準) | 標準で gem が少ないのは利点。ただし国内外の実務・OSS・求人では RSpec の採用例が多く、学習の転用先が広いと判断した |

## 結果

- 良い: 実務で多い書き方に慣れられる。`describe` / `context` で仕様を日本語で表現しやすい
- 悪い: Rails ガイドのテストの章 (Minitest) をそのまま使えない
- 注意: fixtures は使わず FactoryBot に統一する
