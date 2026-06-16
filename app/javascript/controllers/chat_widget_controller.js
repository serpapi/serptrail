import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "messageInput", "submitButton"]
  static values = { open: Boolean }

  connect() {
    this.pending = false
    this.applyOpenState()
    this.scrollToBottom()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  openValueChanged() {
    this.applyOpenState()
    if (this.openValue) this.scrollToBottom()
  }

  submitStart(event) {
    if (this.pending) {
      event.preventDefault()
      return
    }

    const message = this.messageInputTarget.value.trim()
    if (!message) {
      event.preventDefault()
      return
    }

    this.pending = true
    this.appendUserMessage(message)
    this.appendThinkingMessage()
    this.setComposerDisabled(true)
    this.scrollToBottom()
  }

  submitEnd() {
    this.pending = false
    this.setComposerDisabled(false)
  }

  submitWithEnter(event) {
    if (event.key !== "Enter" || event.shiftKey) return

    event.preventDefault()
    event.target.form.requestSubmit()
  }

  applyOpenState() {
    this.element.classList.toggle("is-open", this.openValue)
  }

  appendUserMessage(message) {
    if (!this.hasMessagesTarget) return

    this.removeEmptyState()
    this.messagesTarget.appendChild(this.buildMessageElement("user", "You", message))
  }

  appendThinkingMessage() {
    if (!this.hasMessagesTarget) return

    const messageElement = this.buildMessageElement("assistant", "SerpTrail", "Thinking…")
    messageElement.classList.add("chat-message-pending")
    this.messagesTarget.appendChild(messageElement)
  }

  buildMessageElement(role, label, content) {
    const wrapper = document.createElement("div")
    wrapper.classList.add("chat-message", `chat-message-${role}`)

    const roleElement = document.createElement("div")
    roleElement.classList.add("chat-message-role")
    roleElement.textContent = label

    const contentElement = document.createElement("div")
    contentElement.classList.add("chat-message-content")
    contentElement.textContent = content

    wrapper.append(roleElement, contentElement)
    return wrapper
  }

  removeEmptyState() {
    this.messagesTarget.querySelector(".chat-widget-empty")?.remove()
  }

  setComposerDisabled(disabled) {
    this.element.classList.toggle("is-waiting", disabled)

    if (this.hasMessageInputTarget) this.messageInputTarget.readOnly = disabled
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = disabled
      this.submitButtonTarget.value = disabled ? "Sending…" : "Send"
    }
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return

    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
      if (this.openValue && this.hasMessageInputTarget && !this.pending) this.messageInputTarget.focus()
    })
  }
}
