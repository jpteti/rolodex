import { Controller } from "@hotwired/stimulus"

// Runs a WebAuthn ceremony: fetch options from the server, ask the browser for a
// credential, and post the credential back. The server answers with a redirect URL.
export default class extends Controller {
  static targets = [ "name", "error", "button" ]
  static values = { optionsUrl: String, submitUrl: String, mode: String }

  async run(event) {
    event.preventDefault()
    this.showError("")
    this.buttonTarget.disabled = true

    try {
      const options = await this.post(this.optionsUrlValue)
      const credential = this.modeValue === "register"
        ? await navigator.credentials.create({ publicKey: creationOptions(options) })
        : await navigator.credentials.get({ publicKey: requestOptions(options) })

      const result = await this.post(this.submitUrlValue, {
        credential: serialize(credential),
        name: this.hasNameTarget ? this.nameTarget.value : undefined
      })
      window.Turbo.visit(result.redirect_to)
    } catch (error) {
      this.showError(error.name === "NotAllowedError" ? "The passkey request was cancelled." : error.message)
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  async post(url, body = {}) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content
      },
      body: JSON.stringify(body)
    })
    const json = await response.json()
    if (!response.ok) throw new Error(json.error || "Something went wrong.")
    return json
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = message === ""
  }
}

function decode(value) {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/")
  return Uint8Array.from(atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, "=")), c => c.charCodeAt(0))
}

function encode(buffer) {
  return btoa(String.fromCharCode(...new Uint8Array(buffer))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
}

function creationOptions(options) {
  return {
    ...options,
    challenge: decode(options.challenge),
    user: { ...options.user, id: decode(options.user.id) },
    excludeCredentials: (options.excludeCredentials || []).map(c => ({ ...c, id: decode(c.id) }))
  }
}

function requestOptions(options) {
  return {
    ...options,
    challenge: decode(options.challenge),
    allowCredentials: (options.allowCredentials || []).map(c => ({ ...c, id: decode(c.id) }))
  }
}

function serialize(credential) {
  const response = { clientDataJSON: encode(credential.response.clientDataJSON) }
  if (credential.response.attestationObject) {
    response.attestationObject = encode(credential.response.attestationObject)
    response.transports = credential.response.getTransports?.() || []
  } else {
    response.authenticatorData = encode(credential.response.authenticatorData)
    response.signature = encode(credential.response.signature)
    if (credential.response.userHandle) response.userHandle = encode(credential.response.userHandle)
  }

  return {
    type: credential.type,
    id: credential.id,
    rawId: encode(credential.rawId),
    authenticatorAttachment: credential.authenticatorAttachment,
    clientExtensionResults: credential.getClientExtensionResults(),
    response
  }
}
