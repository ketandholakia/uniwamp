<?php
declare(strict_types=1);

function dashboardH(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}

function dashboardCoreLoadConfig(string $configFile): array
{
    if (!is_file($configFile)) {
        return [];
    }

    $configText = (string) file_get_contents($configFile);
    $configText = preg_replace('/^\xEF\xBB\xBF/', '', $configText);
    $decoded = json_decode($configText, true);
    return is_array($decoded) ? $decoded : [];
}

function dashboardWinQuote(string $value): string
{
    return '"' . str_replace('"', '""', $value) . '"';
}

function dashboardCoreShellArg(string $value): string
{
    if ($value === '') {
        return '""';
    }

    return preg_match('/[\s"&<>|^]/', $value) === 1 ? dashboardWinQuote($value) : $value;
}

function dashboardRunCommand(string $command, ?string $workingDir = null): array
{
    $descriptors = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];
    $process = proc_open('cmd.exe /d /c ' . $command, $descriptors, $pipes, $workingDir);
    if (!is_resource($process)) {
        return ['success' => false, 'code' => -1, 'output' => 'Unable to start process.'];
    }

    fclose($pipes[0]);
    $stdout = stream_get_contents($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    $code = proc_close($process);

    return [
        'success' => $code === 0,
        'code' => $code,
        'output' => trim($stdout . "\n" . $stderr),
    ];
}

function dashboardReadPid(string $pidFile): int
{
    if (!is_file($pidFile)) {
        return 0;
    }

    $pidText = trim((string) file_get_contents($pidFile));
    return ctype_digit($pidText) ? (int) $pidText : 0;
}

function dashboardTempDir(): string
{
    if (function_exists('sys_get_temp_dir')) {
        $tempDir = sys_get_temp_dir();
        if ($tempDir !== '') {
            return $tempDir;
        }
    }

    $fallback = dirname(__DIR__, 2) . DIRECTORY_SEPARATOR . 'runtime';
    return is_dir($fallback) ? $fallback : dirname(__DIR__, 2);
}

function dashboardWaitForPort(int $port, bool $shouldBeOpen, int $timeoutMs = 12000): bool
{
    $deadline = microtime(true) + ($timeoutMs / 1000);
    do {
        $socket = @fsockopen('127.0.0.1', $port, $errorCode, $errorMessage, 0.2);
        $isOpen = is_resource($socket);
        if ($isOpen) {
            fclose($socket);
        }
        if ($isOpen === $shouldBeOpen) {
            return true;
        }
        usleep(250000);
    } while (microtime(true) < $deadline);

    return false;
}

function dashboardCoreProcessExists(int $pid): bool
{
    if ($pid <= 0) {
        return false;
    }

    $result = dashboardRunCommand('tasklist /FI "PID eq ' . $pid . '" /FO CSV /NH');
    return $result['success'] && str_contains($result['output'], (string) $pid);
}

function dashboardCoreProcessImageName(int $pid): string
{
    if ($pid <= 0) {
        return '';
    }

    $result = dashboardRunCommand('tasklist /FI "PID eq ' . $pid . '" /FO CSV /NH');
    if (!$result['success']) {
        return '';
    }

    $output = trim((string) $result['output']);
    if ($output === '') {
        return '';
    }

    $lines = preg_split("/\r\n|\n|\r/", $output) ?: [];
    if (count($lines) === 0) {
        return '';
    }

    $fields = str_getcsv($lines[0], ',', '"', '\\');
    return isset($fields[0]) ? trim((string) $fields[0], " \t\n\r\0\x0B\"") : '';
}

function dashboardCoreProcessMatchesImage(int $pid, array $expectedImageNames): bool
{
    $imageName = strtolower(dashboardCoreProcessImageName($pid));
    if ($imageName === '') {
        return false;
    }

    $expectedImageNames = array_map(static fn(string $value): string => strtolower($value), $expectedImageNames);
    return in_array($imageName, $expectedImageNames, true);
}

function dashboardDefaultPhpExtensions(): array
{
    return [
        'php_bz2.dll',
        'php_curl.dll',
        'php_exif.dll',
        'php_fileinfo.dll',
        'php_gd.dll',
        'php_gettext.dll',
        'php_intl.dll',
        'php_mbstring.dll',
        'php_mysqli.dll',
        'php_opcache.dll',
        'php_openssl.dll',
        'php_pdo_mysql.dll',
        'php_pdo_sqlite.dll',
        'php_sqlite3.dll',
        'php_zip.dll',
    ];
}

function dashboardDetectPhpExtensions(string $phpExtDir): array
{
    if (!is_dir($phpExtDir)) {
        return [];
    }

    $extensions = [];
    foreach ((scandir($phpExtDir) ?: []) as $entry) {
        if ($entry === '.' || $entry === '..') {
            continue;
        }
        if (!preg_match('/^php_[a-z0-9_]+\.dll$/i', $entry)) {
            continue;
        }
        if (in_array(strtolower($entry), ['php_dl_test.dll', 'php_zend_test.dll'], true)) {
            continue;
        }
        $extensions[] = $entry;
    }

    natcasesort($extensions);
    return array_values($extensions);
}

function dashboardNormalizePhpExtensions(array $extensions, array $availableExtensions = []): array
{
    $availableMap = [];
    foreach ($availableExtensions as $extension) {
        $availableMap[strtolower((string) $extension)] = true;
    }

    $normalized = [];
    $seen = [];
    $restrictToAvailable = $availableMap !== [];
    foreach ($extensions as $extension) {
        $extension = trim((string) $extension);
        if ($extension === '') {
            continue;
        }
        $key = strtolower($extension);
        if (isset($seen[$key])) {
            continue;
        }
        if ($restrictToAvailable && !isset($availableMap[$key])) {
            continue;
        }
        $seen[$key] = true;
        $normalized[] = $extension;
    }

    return $normalized;
}

function dashboardLoadEnabledPhpExtensions(array $config, array $availableExtensions): array
{
    if (array_key_exists('phpEnabledExtensions', $config) && is_array($config['phpEnabledExtensions'])) {
        return dashboardNormalizePhpExtensions($config['phpEnabledExtensions'], $availableExtensions);
    }

    return dashboardNormalizePhpExtensions(dashboardDefaultPhpExtensions(), $availableExtensions);
}

function dashboardPhpExtensionLines(array $extensions): string
{
    $lines = [];
    foreach ($extensions as $extension) {
        $extension = trim((string) $extension);
        if ($extension === '') {
            continue;
        }
        $lines[] = strcasecmp($extension, 'php_opcache.dll') === 0 ? 'zend_extension=' . $extension : 'extension=' . $extension;
    }

    return implode(PHP_EOL, $lines);
}

function dashboardCoreDefaultApacheModules(): array
{
    return [
        'mod_access_compat.so',
        'mod_alias.so',
        'mod_auth_basic.so',
        'mod_authn_core.so',
        'mod_authn_file.so',
        'mod_authz_core.so',
        'mod_authz_host.so',
        'mod_authz_user.so',
        'mod_dir.so',
        'mod_env.so',
        'mod_headers.so',
        'mod_include.so',
        'mod_log_config.so',
        'mod_mime.so',
        'mod_rewrite.so',
        'mod_setenvif.so',
        'mod_ssl.so',
        'mod_socache_shmcb.so',
        'mod_unixd.so',
    ];
}

function dashboardCoreDetectApacheModules(string $apacheModuleDir): array
{
    if (!is_dir($apacheModuleDir)) {
        return [];
    }

    $modules = [];
    foreach ((scandir($apacheModuleDir) ?: []) as $entry) {
        if ($entry === '.' || $entry === '..') {
            continue;
        }
        if (!preg_match('/^mod_[a-z0-9_]+\.(so|dll)$/i', $entry)) {
            continue;
        }
        $modules[] = $entry;
    }

    natcasesort($modules);
    return array_values($modules);
}

function dashboardCoreNormalizeApacheModules(array $modules, array $availableModules = []): array
{
    $availableMap = [];
    foreach ($availableModules as $module) {
        $availableMap[strtolower((string) $module)] = true;
    }

    $normalized = [];
    $seen = [];
    $restrictToAvailable = $availableMap !== [];
    foreach ($modules as $module) {
        $module = trim((string) $module);
        if ($module === '') {
            continue;
        }
        $key = strtolower($module);
        if (isset($seen[$key])) {
            continue;
        }
        if ($restrictToAvailable && !isset($availableMap[$key])) {
            continue;
        }
        $seen[$key] = true;
        $normalized[] = $module;
    }

    return $normalized;
}

function dashboardCoreLoadEnabledApacheModules(array $config, array $availableModules): array
{
    if (array_key_exists('apacheEnabledModules', $config) && is_array($config['apacheEnabledModules'])) {
        return dashboardCoreNormalizeApacheModules($config['apacheEnabledModules'], $availableModules);
    }

    return dashboardCoreNormalizeApacheModules(dashboardCoreDefaultApacheModules(), $availableModules);
}

function dashboardCoreApacheModuleLabel(string $module): string
{
    $base = strtolower(pathinfo($module, PATHINFO_FILENAME));
    if (str_starts_with($base, 'mod_')) {
        $base = substr($base, 4);
    }
    $base = str_replace(['_', '-'], ' ', $base);
    return ucwords($base);
}

function dashboardCoreApacheModuleDescription(string $module): string
{
    switch (strtolower($module)) {
        case 'mod_rewrite.so':
        case 'mod_rewrite.dll':
            return 'Enables URL rewriting via RewriteRule and RewriteCond.';
        case 'mod_ssl.so':
        case 'mod_ssl.dll':
            return 'Adds HTTPS support and SSL/TLS directives.';
        case 'mod_headers.so':
        case 'mod_headers.dll':
            return 'Lets Apache add, set, or remove HTTP headers.';
        case 'mod_deflate.so':
        case 'mod_deflate.dll':
            return 'Adds response compression support.';
        case 'mod_dir.so':
        case 'mod_dir.dll':
            return 'Provides trailing slash redirects and directory indexes.';
        case 'mod_mime.so':
        case 'mod_mime.dll':
            return 'Maps file extensions to MIME types.';
        default:
            return 'LoadModule ' . dashboardCoreApacheModuleLabel($module) . ' for Apache.';
    }
}

function dashboardCoreApacheModuleLines(array $modules, string $apacheModuleDir): string
{
    $lines = [];
    foreach ($modules as $module) {
        $module = trim((string) $module);
        if ($module === '') {
            continue;
        }
        $modulePath = $apacheModuleDir . DIRECTORY_SEPARATOR . $module;
        if (!is_file($modulePath)) {
            continue;
        }
        $symbol = pathinfo($module, PATHINFO_FILENAME);
        if (str_starts_with($symbol, 'mod_')) {
            $symbol = substr($symbol, 4);
        }
        $lines[] = 'LoadModule ' . $symbol . '_module "' . $modulePath . '"';
    }

    return implode(PHP_EOL, $lines);
}

function dashboardCoreApachePhpModule(string $phpExtDir): string
{
    foreach (['php8apache2_4.dll', 'php7apache2_4.dll'] as $candidateName) {
        $candidate = $phpExtDir . DIRECTORY_SEPARATOR . $candidateName;
        if (is_file($candidate)) {
            return $candidate;
        }
    }

    return $phpExtDir . DIRECTORY_SEPARATOR . 'php8apache2_4.dll';
}

function dashboardCoreServicePaths(string $root, array $config): array
{
    $phpVersion = (string) ($config['selectedPhpVersion'] ?? 'php85');

    return [
        'root' => $root,
        'logsDir' => $root . DIRECTORY_SEPARATOR . 'logs',
        'generatedDir' => $root . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'generated',
        'apacheExe' => $root . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'apache' . DIRECTORY_SEPARATOR . 'bin' . DIRECTORY_SEPARATOR . 'httpd.exe',
        'apacheWorkingDir' => $root . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'apache' . DIRECTORY_SEPARATOR . 'bin',
        'apacheConf' => $root . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'generated' . DIRECTORY_SEPARATOR . 'httpd.conf',
        'apachePidFile' => $root . DIRECTORY_SEPARATOR . 'logs' . DIRECTORY_SEPARATOR . 'httpd.pid',
        'mariadbExe' => $root . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'mariadb' . DIRECTORY_SEPARATOR . 'bin' . DIRECTORY_SEPARATOR . 'mariadbd.exe',
        'mariadbFallbackExe' => $root . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'mariadb' . DIRECTORY_SEPARATOR . 'bin' . DIRECTORY_SEPARATOR . 'mysqld.exe',
        'mariadbWorkingDir' => $root . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'mariadb' . DIRECTORY_SEPARATOR . 'bin',
        'mariadbIni' => $root . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'generated' . DIRECTORY_SEPARATOR . 'mariadb.ini',
        'mariadbPidFile' => $root . DIRECTORY_SEPARATOR . 'logs' . DIRECTORY_SEPARATOR . 'mariadb.pid',
        'phpExtDir' => $root . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'php' . DIRECTORY_SEPARATOR . $phpVersion . DIRECTORY_SEPARATOR . 'ext',
    ];
}

function dashboardCoreRefreshRuntimeState(array $config, array $paths): array
{
    $apachePid = dashboardReadPid($paths['apachePidFile']);
    if ($apachePid === 0) {
        $apachePid = (int) ($config['apachePid'] ?? 0);
    }

    $mariaPid = dashboardReadPid($paths['mariadbPidFile']);
    if ($mariaPid === 0) {
        $mariaPid = (int) ($config['mariaDbPid'] ?? 0);
    }

    $apachePort = (int) ($config['httpPort'] ?? 8080);
    $mariaPort = (int) ($config['databasePort'] ?? $config['dbPort'] ?? 3309);
    $apacheRunning = $apachePid > 0 ? dashboardCoreProcessMatchesImage($apachePid, ['httpd.exe']) : dashboardWaitForPort($apachePort, true, 200);
    $mariaRunning = $mariaPid > 0 ? dashboardCoreProcessMatchesImage($mariaPid, ['mariadbd.exe', 'mysqld.exe']) : dashboardWaitForPort($mariaPort, true, 200);

    $config['apachePid'] = $apacheRunning ? $apachePid : 0;
    $config['mariaDbPid'] = $mariaRunning ? $mariaPid : 0;
    $config['apacheRunning'] = $apacheRunning;
    $config['mariaDbRunning'] = $mariaRunning;

    return $config;
}

function dashboardCoreDiscoverProjects(string $wwwDir, array $vhostMap, int $httpPort): array
{
    $projects = [];
    $entries = @scandir($wwwDir) ?: [];

    foreach ($entries as $entry) {
        if ($entry === '.' || $entry === '..') {
            continue;
        }

        $fullPath = $wwwDir . DIRECTORY_SEPARATOR . $entry;
        if (!is_dir($fullPath)) {
            continue;
        }

        $isVhost = array_key_exists($entry, $vhostMap);
        $projects[] = [
            'name' => $entry,
            'path' => $fullPath,
            'mode' => $isVhost ? 'VHost' : 'WWW',
            'url' => $isVhost
                ? sprintf('http://%s:%d/', $entry, $httpPort)
                : sprintf('http://127.0.0.1:%d/%s/', $httpPort, $entry),
        ];
    }

    usort($projects, static function (array $left, array $right): int {
        return strcmp($left['name'], $right['name']);
    });

    return $projects;
}

function dashboardIsStackRunning(array $config): bool
{
    return !empty($config['apacheRunning']) && !empty($config['mariaDbRunning']);
}

function dashboardLoadState(string $root): array
{
    $configFile = $root . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'uniwamp.json';
    $config = dashboardCoreLoadConfig($configFile);
    $paths = dashboardCoreServicePaths($root, $config);
    $config = dashboardCoreRefreshRuntimeState($config, $paths);

    $httpPort = (int) ($config['httpPort'] ?? 8080);
    $httpsPort = (int) ($config['httpsPort'] ?? 8443);
    $dbPort = (int) ($config['databasePort'] ?? $config['dbPort'] ?? 3309);
    $hostName = (string) ($config['hostName'] ?? 'localhost');
    $phpVersion = (string) ($config['selectedPhpVersion'] ?? 'php85');
    $nodeVersion = (string) ($config['selectedNodeVersion'] ?? '');
    $phpProfile = (string) ($config['phpProfile'] ?? 'development');

    $wwwDir = $root . DIRECTORY_SEPARATOR . 'www';
    $vhosts = is_array($config['vhosts'] ?? null) ? $config['vhosts'] : [];
    $vhostMap = [];
    foreach ($vhosts as $vhost) {
        if (!is_array($vhost) || empty($vhost['serverName'])) {
            continue;
        }
        $vhostMap[(string) $vhost['serverName']] = $vhost;
    }

    $projects = dashboardCoreDiscoverProjects($wwwDir, $vhostMap, $httpPort);
    $projectCount = count($projects);
    $vhostProjectCount = 0;
    foreach ($projects as $project) {
        if (($project['mode'] ?? '') === 'VHost') {
            $vhostProjectCount++;
        }
    }

    $logsDir = $root . DIRECTORY_SEPARATOR . 'logs';
    $activityLines = dashboardReadTail($logsDir . DIRECTORY_SEPARATOR . 'activity.log', 10);
    $serviceHistoryLines = array_values(array_filter($activityLines, static fn(string $line): bool => preg_match('/\b(Start all|Apache|MariaDB|Stack|Stop all)\b/i', $line) === 1));

    $availablePhpExtensions = dashboardDetectPhpExtensions($paths['phpExtDir']);
    $enabledPhpExtensions = dashboardLoadEnabledPhpExtensions($config, $availablePhpExtensions);
    $missingPhpExtensions = array_values(array_diff($enabledPhpExtensions, $availablePhpExtensions));

    $availableApacheModules = dashboardCoreDetectApacheModules($root . DIRECTORY_SEPARATOR . 'runtime' . DIRECTORY_SEPARATOR . 'apache' . DIRECTORY_SEPARATOR . 'modules');
    $enabledApacheModules = dashboardCoreLoadEnabledApacheModules($config, $availableApacheModules);

    $adminerUrl = sprintf(
        'http://%s:%d/adminer/index.php?%s',
        $hostName,
        $httpPort,
        http_build_query([
            'server' => '127.0.0.1:' . $dbPort,
            'username' => 'root',
        ])
    );

    return [
        'root' => $root,
        'config' => $config,
        'hostName' => $hostName,
        'httpPort' => $httpPort,
        'httpsPort' => $httpsPort,
        'dbPort' => $dbPort,
        'databasePort' => $dbPort,
        'phpVersion' => $phpVersion,
        'nodeVersion' => $nodeVersion,
        'phpProfile' => $phpProfile,
        'stackHealth' => dashboardIsStackRunning($config) ? 'Healthy' : ((!empty($config['apacheRunning']) || !empty($config['mariaDbRunning'])) ? 'Partial' : 'Stopped'),
        'apacheRunning' => !empty($config['apacheRunning']),
        'mariaDbRunning' => !empty($config['mariaDbRunning']),
        'apacheStatus' => !empty($config['apacheRunning']) ? 'Started' : 'Stopped',
        'mariaStatus' => !empty($config['mariaDbRunning']) ? 'Started' : 'Stopped',
        'projectCount' => $projectCount,
        'vhostCount' => count($vhosts),
        'vhostProjectCount' => $vhostProjectCount,
        'recentVhosts' => array_slice($vhosts, -6),
        'projects' => $projects,
        'activityLines' => $activityLines,
        'serviceHistoryLines' => $serviceHistoryLines,
        'availablePhpExtensions' => $availablePhpExtensions,
        'enabledPhpExtensions' => $enabledPhpExtensions,
        'missingPhpExtensions' => $missingPhpExtensions,
        'availableApacheModules' => $availableApacheModules,
        'enabledApacheModules' => $enabledApacheModules,
        'lastApacheError' => (string) ($config['lastApacheError'] ?? ''),
        'lastMariaDbError' => (string) ($config['lastMariaDbError'] ?? ''),
        'lastHostsSyncStatus' => (string) ($config['lastHostsSyncStatus'] ?? ''),
        'overviewUrl' => '/dashboard/',
        'servicesUrl' => '/dashboard/services.php',
        'phpExtensionsUrl' => '/dashboard/php-extensions.php',
        'vhostsUrl' => '/dashboard/vhosts.php',
        'logsUrl' => '/dashboard/logs.php',
        'apacheModulesUrl' => '/dashboard/apache-modules.php',
        'projectsUrl' => '/dashboard/projects.php',
        'adminerUrl' => $adminerUrl,
        'apacheUrl' => sprintf('http://127.0.0.1:%d/', $httpPort),
        'dashboardUrl' => '/dashboard/',
        'dashboardReadOnly' => true,
    ];
}

function dashboardReadTail(string $file, int $maxLines = 10): array
{
    if (!is_file($file)) {
        return [];
    }

    $content = trim((string) file_get_contents($file));
    if ($content === '') {
        return [];
    }

    $lines = preg_split("/\r\n|\n|\r/", $content) ?: [];
    if (count($lines) > $maxLines) {
        $lines = array_slice($lines, -$maxLines);
    }

    return array_values(array_filter(array_map('trim', $lines), static fn(string $line): bool => $line !== ''));
}

function dashboardHandleRequest(array $state): void
{
    $method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
    if ($method === 'GET' || $method === 'HEAD') {
        return;
    }
    header('Allow: GET, HEAD', true);
    header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0', true);
    header('Pragma: no-cache', true);
    http_response_code(405);
    header('Content-Type: text/plain; charset=UTF-8', true);
    echo 'Dashboard is read-only. Use the UniWamp desktop app for changes.';
    exit;
}

function dashboardRenderLayout(array $state, string $pageKey, string $pageTitle, callable $body): void
{
    $navItems = [
        ['key' => 'overview', 'label' => 'Overview', 'href' => $state['overviewUrl']],
        ['key' => 'services', 'label' => 'Services', 'href' => $state['servicesUrl']],
        ['key' => 'php-extensions', 'label' => 'PHP Extensions', 'href' => $state['phpExtensionsUrl']],
        ['key' => 'vhosts', 'label' => 'Virtual Hosts', 'href' => $state['vhostsUrl']],
        ['key' => 'logs', 'label' => 'Logs', 'href' => $state['logsUrl']],
        ['key' => 'apache-modules', 'label' => 'Apache Modules', 'href' => $state['apacheModulesUrl']],
        ['key' => 'projects', 'label' => 'Projects', 'href' => $state['projectsUrl']],
        ['key' => 'adminer', 'label' => 'Adminer', 'href' => $state['adminerUrl'], 'external' => true],
    ];
    ?>
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title><?php echo dashboardH($pageTitle); ?> - UniWamp</title>
      <link rel="icon" href="/dashboard/favicon.ico">
      <link href="/dashboard/style.css" rel="stylesheet">
      <link href="/dashboard/custom.css" rel="stylesheet">
      <script>
        (function () {
          try {
            var savedTheme = localStorage.getItem('uniwamp-theme');
            var prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
            if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
              document.documentElement.classList.add('dark');
            }
          } catch (e) {}
        })();
      </script>
    </head>
    <body class="dashboard-body text-slate-900 dark:text-slate-100">
      <div class="dashboard-shell">
        <aside class="dashboard-sidebar">
          <a href="<?php echo dashboardH($state['overviewUrl']); ?>" class="dashboard-brand">
            <div class="dashboard-brand-mark">
              <img src="/src/images/logo/logo_uniwamp_512.png" alt="UniWamp">
            </div>
            <div>
              <div class="dashboard-brand-title">UniWamp</div>
              <div class="dashboard-brand-subtitle">Local stack dashboard</div>
            </div>
          </a>

          <nav class="dashboard-nav">
            <?php foreach ($navItems as $item): ?>
              <?php $active = $pageKey === $item['key']; ?>
              <a
                href="<?php echo dashboardH($item['href']); ?>"
                <?php echo !empty($item['external']) ? 'target="_blank" rel="noreferrer noopener"' : ''; ?>
                class="dashboard-nav-link <?php echo $active ? 'is-active' : ''; ?>"
              >
                <span class="dashboard-nav-label"><?php echo dashboardH($item['label']); ?></span>
                <span class="dashboard-nav-caret"><?php echo $active ? '•' : '›'; ?></span>
              </a>
            <?php endforeach; ?>
          </nav>
        </aside>

        <div class="dashboard-main">
          <header class="dashboard-topbar">
            <div>
              <h1 class="dashboard-title"><?php echo dashboardH($pageTitle); ?></h1>
            </div>

            <div class="dashboard-topbar-actions">
              <button id="theme-toggle" type="button" class="dashboard-topbar-button" aria-label="Toggle theme">
                <span class="theme-toggle-label">Dark mode</span>
              </button>
            </div>
          </header>

          <main class="dashboard-content">
            <nav class="dashboard-mobile-nav lg:hidden">
              <?php foreach ($navItems as $item): ?>
                <a
                  href="<?php echo dashboardH($item['href']); ?>"
                  <?php echo !empty($item['external']) ? 'target="_blank" rel="noreferrer noopener"' : ''; ?>
                  class="rounded-full border px-3 py-2 text-xs font-medium <?php echo $pageKey === $item['key'] ? 'border-brand-200 bg-brand-50 text-brand-700' : 'border-slate-200 bg-white text-slate-600'; ?>"
                >
                  <?php echo dashboardH($item['label']); ?>
                </a>
              <?php endforeach; ?>
            </nav>

            <?php if (!empty($_GET['notice'])): ?>
              <div class="dashboard-notice rounded-2xl border border-success-200 bg-success-50 px-4 py-3 text-sm text-success-700">
                <?php echo dashboardH((string) $_GET['notice']); ?>
              </div>
            <?php endif; ?>
            <?php if (!empty($_GET['error'])): ?>
              <div class="dashboard-notice rounded-2xl border border-error-200 bg-error-50 px-4 py-3 text-sm text-error-700">
                <?php echo dashboardH((string) $_GET['error']); ?>
              </div>
            <?php endif; ?>

            <?php $body($state); ?>
          </main>
        </div>
      </div>

      <script>
        (function () {
          var toggle = document.getElementById('theme-toggle');
          if (!toggle) return;

          var label = toggle.querySelector('.theme-toggle-label');

          function syncThemeLabel() {
            var isDark = document.documentElement.classList.contains('dark');
            if (label) label.textContent = isDark ? 'Light mode' : 'Dark mode';
            toggle.setAttribute('aria-label', isDark ? 'Switch to light mode' : 'Switch to dark mode');
          }

          toggle.addEventListener('click', function () {
            var isDark = document.documentElement.classList.toggle('dark');
            try {
              localStorage.setItem('uniwamp-theme', isDark ? 'dark' : 'light');
            } catch (e) {}
            syncThemeLabel();
          });

          syncThemeLabel();
        })();
      </script>
    </body>
    </html>
    <?php
}
