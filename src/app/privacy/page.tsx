export default function PrivacyPolicy() {
  return (
    <main className="max-w-3xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6">Privacy Policy</h1>

      <p className="text-gray-600 mb-4">
        <strong>Last Updated:</strong> {new Date().toISOString().split('T')[0]}
      </p>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Introduction</h2>
        <p className="text-gray-700">
          Welcome to PRIMMO. This Privacy Policy explains how we collect, use, and protect
          your information when you use our application.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Information We Collect</h2>
        <h3 className="text-lg font-medium mb-2">Information You Provide</h3>
        <ul className="list-disc list-inside text-gray-700 mb-4">
          <li>Account information (email, name)</li>
          <li>User-generated content</li>
          <li>Settings and preferences</li>
        </ul>

        <h3 className="text-lg font-medium mb-2">Automatically Collected Information</h3>
        <ul className="list-disc list-inside text-gray-700">
          <li>Device information</li>
          <li>Usage statistics</li>
          <li>Crash reports</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">How We Use Your Information</h2>
        <p className="text-gray-700">We use the information we collect to:</p>
        <ul className="list-disc list-inside text-gray-700 mt-2">
          <li>Provide and maintain the app</li>
          <li>Improve user experience</li>
          <li>Send important notifications</li>
          <li>Analyze app usage patterns</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Data Storage</h2>
        <p className="text-gray-700">
          Your data is stored securely using industry-standard encryption.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Data Sharing</h2>
        <p className="text-gray-700">
          We do not sell your personal information. We may share data with:
        </p>
        <ul className="list-disc list-inside text-gray-700 mt-2">
          <li>Service providers (hosting, analytics)</li>
          <li>Legal authorities when required by law</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Your Rights</h2>
        <p className="text-gray-700">You have the right to:</p>
        <ul className="list-disc list-inside text-gray-700 mt-2">
          <li>Access your data</li>
          <li>Request data deletion</li>
          <li>Export your data</li>
          <li>Opt out of analytics</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Children&apos;s Privacy</h2>
        <p className="text-gray-700">
          This app is not intended for children under 13. We do not knowingly
          collect information from children.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Changes to This Policy</h2>
        <p className="text-gray-700">
          We may update this Privacy Policy from time to time. We will notify you
          of any changes by posting the new policy on this page.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-3">Contact Us</h2>
        <p className="text-gray-700">
          If you have questions about this Privacy Policy, please contact us.
        </p>
      </section>
    </main>
  )
}
