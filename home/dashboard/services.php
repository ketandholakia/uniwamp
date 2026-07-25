<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

dashboardRenderLayout($state, 'services', 'Services', static function (array $state): void {
    ?>
    <section class="dashboard-metrics-grid mb-6">
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Host</div>
        <div class="mt-3 text-lg font-semibold text-slate-950"><?php echo dashboardH($state['hostName']); ?></div>
        <p class="mt-2 text-sm text-slate-600">HTTP <?php echo (int) $state['httpPort']; ?>, HTTPS <?php echo (int) $state['httpsPort']; ?></p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Database</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) $state['dbPort']; ?></div>
        <p class="mt-2 text-sm text-slate-600">MariaDB connection port</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">PHP profile</div>
        <div class="mt-3 text-lg font-semibold text-slate-950"><?php echo dashboardH($state['phpVersion']); ?></div>
        <p class="mt-2 text-sm text-slate-600"><?php echo dashboardH($state['phpProfile']); ?> profile</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Node</div>
        <div class="mt-3 text-lg font-semibold text-slate-950"><?php echo dashboardH($state['nodeVersion'] !== '' ? $state['nodeVersion'] : 'Not selected'); ?></div>
        <p class="mt-2 text-sm text-slate-600"><?php echo $state['stackHealth'] === 'Healthy' ? 'Stack ready' : 'Check stack state'; ?></p>
      </article>
    </section>

    <section class="grid gap-4 lg:grid-cols-2">
      <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="text-xl font-semibold text-slate-950">Stack controls</h2>
        <p class="mt-2 text-sm text-slate-600">Service management is disabled in the web dashboard. Use the UniWamp desktop app for start, stop, and restart actions.</p>

        <div class="mt-5 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          Read-only mode: configuration and process actions are only available in the desktop application.
        </div>
      </article>

      <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="text-xl font-semibold text-slate-950">Service actions</h2>
        <div class="mt-4 grid gap-4 sm:grid-cols-2">
          <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="text-sm font-semibold text-slate-950">Apache</div>
            <div class="mt-3 rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-600">Current status: <?php echo $state['apacheRunning'] ? 'Running' : 'Stopped'; ?></div>
          </div>

          <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="text-sm font-semibold text-slate-950">MariaDB</div>
            <div class="mt-3 rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-600">Current status: <?php echo $state['mariaDbRunning'] ? 'Running' : 'Stopped'; ?></div>
          </div>
        </div>
      </article>
    </section>
    <?php
});
