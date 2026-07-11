<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

dashboardRenderLayout($state, 'vhosts', 'Virtual Hosts', static function (array $state): void {
    ?>
    <section class="dashboard-metrics-grid mb-6">
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Configured</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) $state['vhostCount']; ?></div>
        <p class="mt-2 text-sm text-slate-600">Virtual host entries</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Projects</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) $state['vhostProjectCount']; ?></div>
        <p class="mt-2 text-sm text-slate-600">Mapped to vhosts</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">HTTP port</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) $state['httpPort']; ?></div>
        <p class="mt-2 text-sm text-slate-600">Local Apache listener</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Host</div>
        <div class="mt-3 text-lg font-semibold text-slate-950"><?php echo dashboardH($state['hostName']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Primary hostname</p>
      </article>
    </section>

    <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="flex items-start justify-between gap-4">
        <div>
          <h2 class="text-xl font-semibold text-slate-950">Virtual hosts</h2>
          <p class="mt-2 text-sm text-slate-600"><?php echo (int) $state['vhostCount']; ?> virtual host entries are configured.</p>
        </div>
        <a href="<?php echo dashboardH($state['projectsUrl']); ?>" class="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700">Open Projects</a>
      </div>

      <div class="mt-6 space-y-3">
        <?php if ($state['recentVhosts'] === []): ?>
          <div class="text-sm text-slate-500">No virtual hosts configured yet.</div>
        <?php else: ?>
          <?php foreach ($state['recentVhosts'] as $vhost): ?>
            <article class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <div class="font-medium text-slate-950"><?php echo dashboardH((string) ($vhost['serverName'] ?? '')); ?></div>
                  <div class="mt-1 text-sm text-slate-500"><?php echo dashboardH((string) ($vhost['documentRoot'] ?? '')); ?></div>
                </div>
                <a class="rounded-xl bg-brand-500 px-3 py-2 text-sm font-medium text-white" href="<?php echo dashboardH(sprintf('http://%s:%d/', (string) ($vhost['serverName'] ?? ''), (int) $state['httpPort'])); ?>" target="_blank" rel="noreferrer noopener">Open</a>
              </div>
            </article>
          <?php endforeach; ?>
        <?php endif; ?>
      </div>
    </section>
    <?php
});
