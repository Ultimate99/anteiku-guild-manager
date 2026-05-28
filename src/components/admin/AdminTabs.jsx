import React from 'react';

export function AdminTabs({ tabs, activeTab, onChange }) {
  if (tabs.length === 0) {
    return null;
  }

  return (
    <div className="admin-tab-shell">
      <select
        className="admin-tab-select"
        value={activeTab}
        onChange={(event) => onChange(event.target.value)}
        aria-label="Admin sections"
      >
        {tabs.map((tab) => (
          <option key={tab.id} value={tab.id}>
            {tab.label}
          </option>
        ))}
      </select>

      <nav className="admin-tab-bar" aria-label="Admin sections">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            type="button"
            className="admin-tab-button"
            data-active={activeTab === tab.id}
            onClick={() => onChange(tab.id)}
            aria-current={activeTab === tab.id ? 'page' : undefined}
          >
            <span>{tab.label}</span>
          </button>
        ))}
      </nav>
    </div>
  );
}
