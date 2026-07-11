<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

$apacheModules = [];
foreach ($state['availableApacheModules'] as $module) {
    $apacheModules[] = [
        'file' => $module,
        'label' => dashboardCoreApacheModuleLabel($module),
        'description' => dashboardCoreApacheModuleDescription($module),
        'checked' => in_array($module, $state['enabledApacheModules'], true),
    ];
}

dashboardRenderLayout($state, 'apache-modules', 'Apache Modules', static function (array $state) use ($apacheModules): void {
    ?>
    <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start">
        <div class="min-w-0 lg:flex-[1_1_0%] lg:min-w-[520px]">
          <h2 class="text-xl font-semibold text-slate-950">Apache modules</h2>
          <p class="mt-2 text-sm text-slate-600">Choose which modules should be written into the generated Apache config.</p>
        </div>
        <div class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600 lg:mt-0 lg:self-start">
          Selected PHP runtime: <span class="font-medium text-slate-950"><?php echo dashboardH($state['phpVersion']); ?></span>
        </div>
        <div class="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 lg:w-[380px] lg:self-start">
          <input
            id="module-search"
            type="search"
            placeholder="Filter modules"
            class="w-full bg-transparent text-sm text-slate-700 outline-none"
          />
        </div>
      </div>

      <form method="post" class="mt-6">
        <input type="hidden" name="dashboard_action" value="apache_modules_save">
        <div class="grid gap-4 xl:grid-cols-[1fr_1.2fr]">
          <div>
            <div class="max-h-[28rem] space-y-2 overflow-auto rounded-3xl border border-slate-200 bg-slate-50 p-3">
              <?php if ($apacheModules === []): ?>
                <div class="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-500">No Apache modules were found in the runtime.</div>
              <?php else: ?>
                <?php foreach ($apacheModules as $module): ?>
                  <label
                    class="module-entry flex cursor-pointer items-center gap-3 rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 transition hover:border-brand-300 hover:bg-brand-50/40"
                    title="<?php echo dashboardH($module['description']); ?>"
                    data-description="<?php echo dashboardH($module['description']); ?>"
                    data-label="<?php echo dashboardH($module['label']); ?>"
                  >
                    <input type="checkbox" name="apache_modules[]" value="<?php echo dashboardH($module['file']); ?>" <?php echo $module['checked'] ? 'checked' : ''; ?> class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500">
                    <span class="font-medium text-slate-950"><?php echo dashboardH($module['label']); ?></span>
                  </label>
                <?php endforeach; ?>
              <?php endif; ?>
            </div>
          </div>

          <div class="rounded-3xl border border-slate-200 bg-slate-50 p-5">
            <h3 class="text-lg font-semibold text-slate-950">Description</h3>
            <p id="apache-module-description" class="mt-3 text-sm leading-6 text-slate-600">Select a module to see its purpose in the list.</p>
            <p class="mt-4 text-sm text-slate-600">This page writes the enabled module set to <code>apacheEnabledModules</code> and regenerates <code>httpd.conf</code>.</p>
          </div>
        </div>

        <div class="mt-6 flex flex-wrap justify-end gap-3">
          <a class="rounded-2xl border border-slate-200 bg-white px-5 py-3 text-sm font-medium text-slate-700" href="<?php echo dashboardH($state['overviewUrl']); ?>">Cancel</a>
          <button class="rounded-2xl bg-brand-500 px-5 py-3 text-sm font-medium text-white shadow-sm" type="submit">Save</button>
        </div>
      </form>
    </section>

    <script>
      (function () {
        const description = document.getElementById('apache-module-description');
        const moduleLabels = document.querySelectorAll('.module-entry');
        const moduleSearch = document.getElementById('module-search');
        const defaultDescription = 'Select a module to see its purpose in the list.';

        moduleLabels.forEach((label) => {
          label.addEventListener('click', () => {
            const text = label.dataset.description || defaultDescription;
            if (description) {
              description.textContent = text;
            }
          });
        });

        if (moduleSearch) {
          moduleSearch.addEventListener('input', () => {
            const query = moduleSearch.value.trim().toLowerCase();
            moduleLabels.forEach((label) => {
              const haystack = `${label.dataset.label || ''} ${label.dataset.description || ''}`.toLowerCase();
              label.style.display = haystack.includes(query) ? '' : 'none';
            });
          });
        }

        if (moduleLabels.length > 0 && description) {
          description.textContent = moduleLabels[0].dataset.description || defaultDescription;
        }
      })();
    </script>
    <?php
});
