import { Controller } from "@hotwired/stimulus"

// テキストエリアの文字数をリアルタイムに表示する
// <div data-controller="char-count">
//   <textarea data-char-count-target="input" data-action="input->char-count#update"></textarea>
//   <span data-char-count-target="output"></span>
// </div>
export default class extends Controller {
  static targets = ["input", "output"]

  connect() {
    this.update()
  }

  update() {
    this.outputTarget.textContent = this.inputTarget.value.length
  }
}
