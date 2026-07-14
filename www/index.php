<?php
declare(strict_types=1);

$root = dirname(__DIR__);
$configFile = $root . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'uniwamp.json';
$config = [];

if (is_file($configFile)) {
    $configText = (string) file_get_contents($configFile);
    $configText = preg_replace('/^\xEF\xBB\xBF/', '', $configText);
    $decoded = json_decode($configText, true);
    if (is_array($decoded)) {
        $config = $decoded;
    }
}

$httpPort = (int) ($config['httpPort'] ?? 8080);
$databasePort = (int) ($config['databasePort'] ?? 3307);
$hostName = (string) ($config['hostName'] ?? 'localhost');
$dashboardUrl = sprintf('http://%s:%d/dashboard/', $hostName, $httpPort);
$adminerUrl = sprintf(
    'http://%s:%d/adminer/index.php?%s',
    $hostName,
    $httpPort,
    http_build_query([
        'server' => '127.0.0.1:' . $databasePort,
        'username' => 'root',
    ])
);

?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>UniWamp Local Site</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #eef4ff;
      --card: rgba(255, 255, 255, 0.9);
      --ink: #10233f;
      --muted: #5c6b84;
      --accent: #1256f7;
      --accent-2: #0d9488;
      --border: rgba(16, 35, 63, 0.12);
      --shadow: 0 24px 80px rgba(16, 35, 63, 0.16);
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: Segoe UI, Arial, sans-serif;
      color: var(--ink);
      background:
        radial-gradient(circle at top left, rgba(18, 86, 247, 0.14), transparent 34%),
        radial-gradient(circle at top right, rgba(13, 148, 136, 0.16), transparent 28%),
        linear-gradient(180deg, #f8fbff 0%, var(--bg) 100%);
    }

    .wrap {
      max-width: 1120px;
      margin: 0 auto;
      padding: 40px 20px 56px;
    }

    .hero {
      border: 1px solid var(--border);
      border-radius: 28px;
      background: linear-gradient(135deg, #0f2747 0%, #124a88 45%, #0f766e 100%);
      color: #fff;
      padding: 30px 32px;
      box-shadow: var(--shadow);
    }

    .hero h1 {
      margin: 0;
      font-size: clamp(2rem, 4vw, 3.2rem);
      line-height: 1.05;
    }

    .hero p {
      margin: 14px 0 0;
      max-width: 760px;
      color: rgba(255, 255, 255, 0.86);
      font-size: 1rem;
      line-height: 1.65;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(12, minmax(0, 1fr));
      gap: 20px;
      margin-top: 20px;
    }

    .card {
      grid-column: span 12;
      border: 1px solid var(--border);
      border-radius: 24px;
      background: var(--card);
      backdrop-filter: blur(14px);
      box-shadow: var(--shadow);
      padding: 22px;
    }

    .card h2 {
      margin: 0 0 8px;
      font-size: 1.25rem;
    }

    .card p {
      margin: 0;
      color: var(--muted);
      line-height: 1.65;
    }

    .links {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      margin-top: 18px;
    }

    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 44px;
      padding: 0 18px;
      border-radius: 14px;
      text-decoration: none;
      font-weight: 700;
      transition: transform 0.15s ease, box-shadow 0.15s ease, background 0.15s ease;
    }

    .btn:hover {
      transform: translateY(-1px);
    }

    .btn-primary {
      color: #fff;
      background: linear-gradient(135deg, var(--accent) 0%, #0f7aea 100%);
      box-shadow: 0 14px 28px rgba(18, 86, 247, 0.24);
    }

    .btn-secondary {
      color: var(--ink);
      background: #fff;
      border: 1px solid var(--border);
    }

    .meta {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 14px;
      margin-top: 18px;
    }

    .meta div {
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 16px;
      background: rgba(255, 255, 255, 0.72);
    }

    .meta label {
      display: block;
      font-size: 0.74rem;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: var(--muted);
      margin-bottom: 8px;
    }

    .meta strong {
      font-size: 1rem;
      word-break: break-word;
    }

    @media (min-width: 960px) {
      .span-7 { grid-column: span 7; }
      .span-5 { grid-column: span 5; }
    }

    @media (max-width: 640px) {
      .wrap { padding: 20px 14px 40px; }
      .hero, .card { border-radius: 20px; padding: 20px; }
      .meta { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <main class="wrap">
    <section class="hero">
      <h1>UniWamp local site</h1>
      <p>
        This is the public web root for your local projects. The control dashboard is kept separately under
        <code>/dashboard/</code> so the main site stays clean and project-focused.
      </p>
    </section>

    <div class="grid">
      <section class="card span-7">
        <h2>Quick access</h2>
        <p>Use the dashboard for service control, virtual host management, logs, and status checks.</p>
        <div class="links">
          <a class="btn btn-primary" href="<?php echo htmlspecialchars($dashboardUrl, ENT_QUOTES); ?>">Open Dashboard</a>
          <a class="btn btn-secondary" href="<?php echo htmlspecialchars($adminerUrl, ENT_QUOTES); ?>">Open Adminer</a>
        </div>
      </section>

      <section class="card span-5">
        <h2>Current endpoint</h2>
        <p>The local site is served from the configured document root and can host plain project folders under `www`.</p>
        <div class="meta">
          <div>
            <label>Host</label>
            <strong><?php echo htmlspecialchars($hostName, ENT_QUOTES); ?></strong>
          </div>
          <div>
            <label>HTTP port</label>
            <strong><?php echo (int) $httpPort; ?></strong>
          </div>
        </div>
      </section>
    </div>
  </main>
</body>
</html>
