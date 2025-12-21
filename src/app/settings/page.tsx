'use client'

export default function Settings() {
  return (
    <main className="max-w-3xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6">Settings</h1>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-4">Preferences</h2>
        <div className="space-y-4">
          <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
            <div>
              <h3 className="font-medium">Notifications</h3>
              <p className="text-sm text-gray-600">Enable push notifications</p>
            </div>
            <button className="px-4 py-2 bg-blue-600 text-white rounded-lg">
              Enable
            </button>
          </div>

          <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
            <div>
              <h3 className="font-medium">Theme</h3>
              <p className="text-sm text-gray-600">Choose your preferred theme</p>
            </div>
            <select className="px-4 py-2 border rounded-lg">
              <option>Light</option>
              <option>Dark</option>
              <option>System</option>
            </select>
          </div>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-4">Account</h2>
        <div className="space-y-4">
          <div className="p-4 bg-gray-50 rounded-lg">
            <h3 className="font-medium mb-2">Profile</h3>
            <p className="text-sm text-gray-600">Manage your profile settings</p>
          </div>

          <div className="p-4 bg-gray-50 rounded-lg">
            <h3 className="font-medium mb-2">Data & Privacy</h3>
            <p className="text-sm text-gray-600">Manage your data and privacy settings</p>
          </div>
        </div>
      </section>
    </main>
  )
}
