/**
 * Public Cards Web Component
 *
 * Usage:
 *   <script src="https://public.cards/embed.js"></script>
 *   <public-card src="https://public.cards/api/cards/123"></public-card>
 */

class PublicCard extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  connectedCallback() {
    const src = this.getAttribute('src');
    if (src) {
      this.fetchCard(src);
    } else {
      this.renderError('No src attribute provided');
    }
  }

  async fetchCard(src) {
    try {
      this.renderLoading();

      const res = await fetch(src, {
        headers: { 'Accept': 'application/json' }
      });

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }

      const card = await res.json();
      this.render(card);

      // Store version info for staleness detection
      this.dataset.version = card.version;
      this.dataset.hash = card.identifier?.value || '';
      this.dataset.src = src;

    } catch (error) {
      this.renderError(`Failed to load card: ${error.message}`);
    }
  }

  renderLoading() {
    this.shadowRoot.innerHTML = `
      <style>${this.getStyles()}</style>
      <div class="card loading">
        <div class="spinner"></div>
        <p>Loading card...</p>
      </div>
    `;
  }

  renderError(message) {
    this.shadowRoot.innerHTML = `
      <style>${this.getStyles()}</style>
      <div class="card error">
        <p>${message}</p>
      </div>
    `;
  }

  render(card) {
    const front = card.mainEntity?.front || {};
    const back = card.mainEntity?.back || {};

    this.shadowRoot.innerHTML = `
      <style>${this.getStyles()}</style>
      <div class="card-container">
        <div class="card" onclick="this.classList.toggle('flipped')">
          <div class="card-face card-front">
            <h2 class="title">${this.escapeHtml(card.name || 'Untitled')}</h2>
            <div class="content">
              ${this.renderContent(front)}
            </div>
            <div class="footer">
              <span class="version">v${card.version || 1}</span>
              <span class="hint">Click to flip</span>
            </div>
          </div>
          <div class="card-face card-back">
            <div class="content">
              ${this.renderContent(back)}
            </div>
            <div class="footer">
              <a href="${card['@id'] || '#'}" target="_blank" class="link">View on Public Cards</a>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  renderContent(obj) {
    if (!obj || Object.keys(obj).length === 0) {
      return '<p class="empty">No content</p>';
    }

    return Object.entries(obj)
      .map(([key, value]) => {
        const label = this.formatLabel(key);
        const displayValue = typeof value === 'object'
          ? JSON.stringify(value)
          : this.escapeHtml(String(value));
        return `<div class="field"><span class="label">${label}</span><span class="value">${displayValue}</span></div>`;
      })
      .join('');
  }

  formatLabel(key) {
    return key
      .replace(/_/g, ' ')
      .replace(/([A-Z])/g, ' $1')
      .replace(/^./, str => str.toUpperCase())
      .trim();
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * Check if the card has been updated since it was embedded
   * Returns true if updated, false if current
   */
  async checkForUpdates() {
    const src = this.dataset.src;
    if (!src) return false;

    try {
      const res = await fetch(src, {
        headers: { 'Accept': 'application/json' }
      });
      const card = await res.json();
      const currentHash = card.identifier?.value || '';

      if (currentHash !== this.dataset.hash) {
        this.showUpdateIndicator();
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }

  showUpdateIndicator() {
    const indicator = document.createElement('div');
    indicator.className = 'update-indicator';
    indicator.textContent = 'Updated';
    indicator.onclick = () => this.fetchCard(this.dataset.src);
    this.shadowRoot.querySelector('.card-container')?.prepend(indicator);
  }

  getStyles() {
    return `
      :host {
        display: block;
        font-family: system-ui, -apple-system, sans-serif;
      }

      .card-container {
        perspective: 1000px;
        max-width: 400px;
      }

      .card {
        position: relative;
        width: 100%;
        min-height: 250px;
        transition: transform 0.6s;
        transform-style: preserve-3d;
        cursor: pointer;
        border-radius: 12px;
        box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
      }

      .card.flipped {
        transform: rotateY(180deg);
      }

      .card-face {
        position: absolute;
        width: 100%;
        min-height: 250px;
        backface-visibility: hidden;
        border-radius: 12px;
        padding: 1.5rem;
        box-sizing: border-box;
        display: flex;
        flex-direction: column;
      }

      .card-front {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
      }

      .card-back {
        background: white;
        border: 1px solid #e5e7eb;
        transform: rotateY(180deg);
        color: #1f2937;
      }

      .title {
        margin: 0 0 1rem 0;
        font-size: 1.25rem;
        font-weight: 600;
      }

      .content {
        flex: 1;
      }

      .field {
        margin-bottom: 0.5rem;
      }

      .label {
        display: block;
        font-size: 0.75rem;
        text-transform: uppercase;
        opacity: 0.7;
        margin-bottom: 0.125rem;
      }

      .value {
        font-size: 0.875rem;
      }

      .footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-top: 1rem;
        font-size: 0.75rem;
        opacity: 0.7;
      }

      .link {
        color: #667eea;
        text-decoration: none;
      }

      .link:hover {
        text-decoration: underline;
      }

      .version {
        background: rgba(255,255,255,0.2);
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
      }

      .card-back .version {
        background: #f3f4f6;
      }

      .loading, .error {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        background: #f9fafb;
        border: 1px solid #e5e7eb;
        color: #6b7280;
      }

      .error {
        color: #dc2626;
      }

      .spinner {
        width: 24px;
        height: 24px;
        border: 2px solid #e5e7eb;
        border-top-color: #667eea;
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
      }

      @keyframes spin {
        to { transform: rotate(360deg); }
      }

      .update-indicator {
        position: absolute;
        top: -8px;
        right: -8px;
        background: #10b981;
        color: white;
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
        font-size: 0.75rem;
        cursor: pointer;
        z-index: 10;
      }

      .empty {
        opacity: 0.5;
        font-style: italic;
      }
    `;
  }
}

// Register the custom element
if (!customElements.get('public-card')) {
  customElements.define('public-card', PublicCard);
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = PublicCard;
}
