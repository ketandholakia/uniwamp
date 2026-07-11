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
        <p class="mt-2 text-sm text-slate-600">Start, stop, or restart the local Apache and MariaDB services.</p>

        <div class="mt-5 flex flex-wrap gap-3">
          <form method="post">
            <input type="hidden" name="dashboard_action" value="stack_start">
            <button class="rounded-2xl border border-success-200 bg-success-50 px-4 py-3 text-sm font-medium text-success-700" type="submit">Start all services</button>
          </form>
          <form method="post">
            <input type="hidden" name="dashboard_action" value="stack_stop">
            <button class="rounded-2xl border border-error-200 bg-error-50 px-4 py-3 text-sm font-medium text-error-700" type="submit" onclick="return confirm('Stop Apache and MariaDB now?');">Stop all services</button>
          </form>
        </div>
      </article>

      <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="text-xl font-semibold text-slate-950">Service actions</h2>
        <div class="mt-4 grid gap-4 sm:grid-cols-2">
          <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="text-sm font-semibold text-slate-950">Apache</div>
            <div class="mt-3 flex flex-wrap gap-2">
              <form method="post">
                <input type="hidden" name="dashboard_action" value="apache_start">
                <button class="rounded-xl border border-brand-200 bg-brand-50 px-4 py-2.5 text-sm font-medium text-brand-700" type="submit" <?php echo $state['apacheRunning'] ? 'disabled' : ''; ?>>Start</button>
              </form>
              <form method="post">
                <input type="hidden" name="dashboard_action" value="apache_stop">
                <button class="rounded-xl border border-error-200 bg-error-50 px-4 py-2.5 text-sm font-medium text-error-700" type="submit" <?php echo $state['apacheRunning'] ? '' : 'disabled'; ?> onclick="return confirm('Stop Apache?');">Stop</button>
              </form>
              <form method="post">
                <input type="hidden" name="dashboard_action" value="apache_restart">
                <button class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-2.5 text-sm font-medium text-amber-700" type="submit" <?php echo $state['apacheRunning'] ? '' : 'disabled'; ?> onclick="return confirm('Restart Apache?');">Restart</button>
              </form>
            </div>
          </div>

          <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="text-sm font-semibold text-slate-950">MariaDB</div>
            <div class="mt-3 flex flex-wrap gap-2">
              <form method="post">
                <input type="hidden" name="dashboard_action" value="mariadb_start">
                <button class="rounded-xl border border-brand-200 bg-brand-50 px-4 py-2.5 text-sm font-medium text-brand-700" type="submit" <?php echo $state['mariaDbRunning'] ? 'disabled' : ''; ?>>Start</button>
              </form>
              <form method="post">
                <input type="hidden" name="dashboard_action" value="mariadb_stop">
                <button class="rounded-xl border border-error-200 bg-error-50 px-4 py-2.5 text-sm font-medium text-error-700" type="submit" <?php echo $state['mariaDbRunning'] ? '' : 'disabled'; ?> onclick="return confirm('Stop MariaDB?');">Stop</button>
              </form>
              <form method="post">
                <input type="hidden" name="dashboard_action" value="mariadb_restart">
                <button class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-2.5 text-sm font-medium text-amber-700" type="submit" <?php echo $state['mariaDbRunning'] ? '' : 'disabled'; ?> onclick="return confirm('Restart MariaDB?');">Restart</button>
              </form>
            </div>
          </div>
        </div>
      </article>
    </section>
    <?php
});
