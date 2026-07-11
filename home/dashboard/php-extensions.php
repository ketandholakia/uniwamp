<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

dashboardRenderLayout($state, 'php-extensions', 'PHP Extensions', static function (array $state): void {
    ?>
    <section class="dashboard-metrics-grid mb-6">
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Available</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) count($state['availablePhpExtensions']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Detected PHP extension files</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Enabled</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) count($state['enabledPhpExtensions']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Written to generated php.ini</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Missing</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) count($state['missingPhpExtensions']); ?></div>
        <p class="mt-2 text-sm text-slate-600">Enabled but not found in runtime</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Profile</div>
        <div class="mt-3 text-xl font-semibold text-slate-950"><?php echo dashboardH($state['phpProfile']); ?></div>
        <p class="mt-2 text-sm text-slate-600">PHP <?php echo dashboardH($state['phpVersion']); ?></p>
      </article>
    </section>

    <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
      <div>
        <div class="flex items-start justify-between gap-4">
          <h2 class="text-xl font-semibold text-slate-950">PHP extension set</h2>
          <div class="w-full max-w-md rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
            <input
              id="php-extension-search"
              type="search"
              placeholder="Search extensions"
              autocomplete="off"
              class="w-full bg-transparent text-sm text-slate-700 outline-none"
            />
          </div>
        </div>
        <p class="mt-2 text-sm text-slate-600">Choose which extensions should be written to <code>config/generated/php.ini</code>.</p>
      </div>

      <form method="post" class="mt-6">
        <input type="hidden" name="dashboard_action" value="php_extensions_save">
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-3" id="php-extension-grid">
          <?php foreach ($state['availablePhpExtensions'] as $extension): ?>
            <label class="flex items-start gap-3 rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm" data-extension-item data-label="<?php echo dashboardH(strtolower($extension)); ?>">
              <input type="checkbox" name="php_extensions[]" value="<?php echo dashboardH($extension); ?>" <?php echo in_array($extension, $state['enabledPhpExtensions'], true) ? 'checked' : ''; ?> class="mt-1">
              <span>
                <span class="block font-medium text-slate-950"><?php echo dashboardH($extension); ?></span>
                <span class="block text-xs text-slate-500"><?php echo dashboardH(str_replace('php_', '', pathinfo($extension, PATHINFO_FILENAME))); ?></span>
              </span>
            </label>
          <?php endforeach; ?>
        </div>

        <div class="mt-6 flex flex-wrap gap-3">
          <button type="submit" class="rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-medium text-white">Save PHP extensions</button>
          <a href="<?php echo dashboardH($state['overviewUrl']); ?>" class="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700">Back to overview</a>
        </div>
      </form>
    </section>

    <?php if ($state['missingPhpExtensions'] !== []): ?>
      <section class="rounded-3xl border border-amber-200 bg-amber-50 p-6 shadow-sm">
        <h3 class="text-lg font-semibold text-amber-900">Missing configured extensions</h3>
        <div class="mt-3 flex flex-wrap gap-2">
          <?php foreach ($state['missingPhpExtensions'] as $extension): ?>
            <span class="rounded-full bg-white px-3 py-1 text-xs font-medium text-amber-800"><?php echo dashboardH($extension); ?></span>
          <?php endforeach; ?>
        </div>
      </section>
    <?php endif; ?>

    <script>
      (function () {
        const search = document.getElementById('php-extension-search');
        const items = Array.from(document.querySelectorAll('[data-extension-item]'));
        if (!search || items.length === 0) return;

        const applyFilter = () => {
          const query = search.value.trim().toLowerCase();
          items.forEach((item) => {
            const label = (item.dataset.label || '').toLowerCase();
            item.style.display = label.includes(query) ? '' : 'none';
          });
        };

        search.addEventListener('input', applyFilter);
        applyFilter();
      })();
    </script>
    <?php
});
