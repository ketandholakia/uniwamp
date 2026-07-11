<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

dashboardRenderLayout($state, 'logs', 'Logs', static function (array $state): void {
    ?>
    <section class="dashboard-metrics-grid mb-6">
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Activity</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) count($state['activityLines']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Recent log entries loaded</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Service history</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) count($state['serviceHistoryLines']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Stack-related events tracked</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Apache</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo dashboardH($state['apacheStatus']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Port <?php echo (int) $state['httpPort']; ?></p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">MariaDB</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo dashboardH($state['mariaStatus']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Port <?php echo (int) $state['dbPort']; ?></p>
      </article>
    </section>

    <section class="grid gap-4 lg:grid-cols-2">
      <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="text-xl font-semibold text-slate-950">Recent activity</h2>
        <p class="mt-2 text-sm text-slate-600">Last lines from <code>logs/activity.log</code>.</p>
        <div class="mt-5 space-y-3">
          <?php if ($state['activityLines'] === []): ?>
            <div class="text-sm text-slate-500">No activity log entries yet.</div>
          <?php else: ?>
            <?php foreach ($state['activityLines'] as $line): ?>
              <div class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700">
                <?php echo dashboardH($line); ?>
              </div>
            <?php endforeach; ?>
          <?php endif; ?>
        </div>
      </article>

      <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="text-xl font-semibold text-slate-950">Service history</h2>
        <p class="mt-2 text-sm text-slate-600">Last stack-related entries only.</p>
        <div class="mt-5 space-y-3">
          <?php if ($state['serviceHistoryLines'] === []): ?>
            <div class="text-sm text-slate-500">No service history captured yet.</div>
          <?php else: ?>
            <?php foreach ($state['serviceHistoryLines'] as $line): ?>
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
