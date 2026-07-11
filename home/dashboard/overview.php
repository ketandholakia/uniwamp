<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

dashboardRenderLayout($state, 'overview', 'UniWamp Dashboard', static function (array $state): void {
    ?>
    <section class="dashboard-metrics-grid mb-6">
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Apache</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo dashboardH($state['apacheStatus']); ?></div>
        <p class="mt-2 text-sm text-slate-600">HTTP port <?php echo (int) $state['httpPort']; ?>, PID <?php echo (int) ($state['config']['apachePid'] ?? 0); ?></p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">MariaDB</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo dashboardH($state['mariaStatus']); ?></div>
        <p class="mt-2 text-sm text-slate-600">DB port <?php echo (int) $state['dbPort']; ?>, PID <?php echo (int) ($state['config']['mariaDbPid'] ?? 0); ?></p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">PHP</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo dashboardH($state['phpVersion']); ?></div>
        <p class="mt-2 text-sm text-slate-600"><?php echo dashboardH($state['phpProfile']); ?> profile</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Stack</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo dashboardH($state['stackHealth']); ?></div>
        <p class="mt-2 text-sm text-slate-600"><?php echo (int) $state['vhostCount']; ?> vhosts and <?php echo (int) $state['projectCount']; ?> project folders detected.</p>
      </article>
    </section>

    <section class="grid gap-4 lg:grid-cols-2">
      <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-slate-950">Quick links</h3>
            <p class="mt-1 text-sm text-slate-500">Move straight to the pages that manage each part of the stack.</p>
          </div>
        </div>
        <div class="mt-4 grid gap-3 sm:grid-cols-2">
          <a class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700" href="<?php echo dashboardH($state['servicesUrl']); ?>">Services</a>
          <a class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700" href="<?php echo dashboardH($state['phpExtensionsUrl']); ?>">PHP Extensions</a>
          <a class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700" href="<?php echo dashboardH($state['vhostsUrl']); ?>">Virtual Hosts</a>
          <a class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700" href="<?php echo dashboardH($state['logsUrl']); ?>">Logs</a>
          <a class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700" href="<?php echo dashboardH($state['apacheModulesUrl']); ?>">Apache Modules</a>
          <a class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700" href="<?php echo dashboardH($state['projectsUrl']); ?>">Projects</a>
        </div>
      </article>

      <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-slate-950">Recent activity</h3>
            <p class="mt-1 text-sm text-slate-500">Last entries from <code>logs/activity.log</code>.</p>
          </div>
        </div>
        <div class="mt-4 space-y-3">
          <?php if ($state['activityLines'] === []): ?>
            <div class="text-sm text-slate-500">No activity logged yet.</div>
          <?php else: ?>
            <?php foreach (array_slice($state['activityLines'], -4) as $line): ?>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700">
                <?php echo dashboardH($line); ?>
              </div>
            <?php endforeach; ?>
          <?php endif; ?>
        </div>
      </article>
    </section>
    <?php
});
