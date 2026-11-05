import { Controller } from "@hotwired/stimulus"

// source ターゲットのテキストをクリップボードにコピーする
// <div data-controller="clipboard" data-clipboard-copied-label-value="コピーしました">
//   <template data-clipboard-target="source">...</template>
//   <button data-action="clipboard#copy" data-clipboard-target="button">コピー</button>
// </div>
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { copiedLabel: { type: String, default: "Copied!" } }

  async copy(event) {
    event.preventDefault()
    const text = this.sourceTarget.content?.textContent ?? this.sourceTarget.textContent
    await this.#write(text.trim())
    this.#flash()
  }

  // navigator.clipboard は安全なコンテキスト (https / localhost) でのみ使えるため、
  // http://192.168.x.x のような LAN アクセス時は execCommand にフォールバックする
  async #write(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text)
    }
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    textarea.remove()
  }

  #flash() {
    if (!this.hasButtonTarget) return
    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = this.copiedLabelValue
    setTimeout(() => { this.buttonTarget.textContent = original }, 1500)
  }
}
