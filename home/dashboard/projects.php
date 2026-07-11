<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require __DIR__ . '/shared.php';

$state = dashboardLoadState($root);
dashboardHandleRequest($state);

$query = trim((string) ($_GET['q'] ?? ''));
$filteredProjects = $state['projects'];
if ($query !== '') {
    $needle = strtolower($query);
    $filteredProjects = array_values(array_filter($state['projects'], static function (array $project) use ($needle): bool {
        $haystack = strtolower(implode(' ', [$project['name'], $project['mode'], $project['url'], $project['path']]));
        return str_contains($haystack, $needle);
    }));
}

dashboardRenderLayout($state, 'projects', 'Projects', static function (array $state) use ($query, $filteredProjects): void {
    ?>
    <section class="dashboard-metrics-grid mb-6">
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Total projects</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) $state['projectCount']; ?></div>
        <p class="mt-2 text-sm text-slate-600">Folders discovered under <code>www</code></p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">VHost mapped</div>
        <div class="mt-3 text-3xl font-semibold text-slate-950"><?php echo (int) $state['vhostProjectCount']; ?></div>
        <p class="mt-2 text-sm text-slate-600">Projects with matching server names</p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Host</div>
        <div class="mt-3 text-xl font-semibold text-slate-950"><?php echo dashboardH($state['hostName']); ?></div>
        <p class="mt-2 text-sm text-slate-600">HTTP port <?php echo (int) $state['httpPort']; ?></p>
      </article>
      <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">Root</div>
        <div class="mt-3 text-xl font-semibold text-slate-950">www</div>
        <p class="mt-2 text-sm text-slate-600">Project folders only</p>
      </article>
    </section>

    <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 class="text-xl font-semibold text-slate-950">Project inventory</h2>
          <p class="mt-2 text-sm text-slate-600">Browse each folder under the web root and see which ones map to a virtual host.</p>
        </div>
        <div class="flex flex-wrap gap-3">
          <a href="<?php echo dashboardH($state['overviewUrl']); ?>" class="rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700">Back to dashboard</a>
          <a href="<?php echo dashboardH($state['adminerUrl']); ?>" target="_blank" rel="noreferrer noopener" class="rounded-2xl bg-brand-500 px-4 py-2.5 text-sm font-medium text-white">Open Adminer</a>
        </div>
      </div>

      <div class="mt-6 flex justify-end">
        <div class="w-full max-w-md rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
          <input id="project-search" type="search" value="<?php echo dashboardH($query); ?>" placeholder="Search projects" autocomplete="off" class="w-full bg-transparent text-sm text-slate-700 outline-none">
        </div>
      </div>

      <div class="mt-6 overflow-hidden rounded-3xl border border-slate-200">
        <?php if ($filteredProjects === []): ?>
          <div class="px-6 py-8 text-sm text-slate-500">
            <?php if ($state['projects'] === []): ?>
              No project folders were found under <code><?php echo dashboardH((string) $state['root'] . DIRECTORY_SEPARATOR . 'www'); ?></code>.
            <?php else: ?>
              No projects match <strong><?php echo dashboardH($query); ?></strong>.
            <?php endif; ?>
          </div>
        <?php else: ?>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[860px] border-collapse">
              <thead>
                <tr class="bg-slate-50 text-left text-xs uppercase tracking-[0.12em] text-slate-500">
                  <th class="px-6 py-4">Project</th>
                  <th class="px-6 py-4">Mode</th>
                  <th class="px-6 py-4">URL</th>
                  <th class="px-6 py-4">Path</th>
                </tr>
              </thead>
              <tbody id="projects-table">
                <?php foreach ($filteredProjects as $project): ?>
                  <tr class="border-t border-slate-200 bg-white align-top" data-project-row>
                    <td class="px-6 py-4">
                      <div class="font-semibold text-slate-950"><?php echo dashboardH($project['name']); ?></div>
                      <div class="mt-1 text-sm text-slate-500">Folder under the web root</div>
                    </td>
                    <td class="px-6 py-4">
                      <span class="inline-flex rounded-full px-3 py-1 text-xs font-semibold <?php echo $project['mode'] === 'VHost' ? 'bg-brand-50 text-brand-700' : 'bg-amber-50 text-amber-700'; ?>">
                        <?php echo dashboardH($project['mode']); ?>
                      </span>
                    </td>
                    <td class="px-6 py-4">
                      <a href="<?php echo dashboardH($project['url']); ?>" class="font-medium text-brand-600" target="_blank" rel="noreferrer noopener">
                        <?php echo dashboardH($project['url']); ?>
                      </a>
                    </td>
                    <td class="px-6 py-4">
                      <div class="break-words text-sm text-slate-500"><?php echo dashboardH($project['path']); ?></div>
                    </td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        <?php endif; ?>
      </div>

      <div class="mt-4 flex flex-wrap justify-between gap-3 text-sm text-slate-500">
        <div><?php echo (int) $state['projectCount']; ?> projects total, <?php echo (int) $state['vhostProjectCount']; ?> matched to vhosts.</div>
        <div><a href="<?php echo dashboardH($state['apacheModulesUrl']); ?>" class="text-brand-600">Apache Modules</a> · <a href="/" class="text-brand-600">Open local site</a></div>
      </div>
    </section>

    <script>
      (function () {
        const search = document.getElementById('project-search');
        const rows = Array.from(document.querySelectorAll('[data-project-row]'));
        if (!search || rows.length === 0) return;

        const applyFilter = () => {
          const query = search.value.trim().toLowerCase();
          rows.forEach((row) => {
            const text = row.textContent ? row.textContent.toLowerCase() : '';
            row.style.display = text.includes(query) ? '' : 'none';
          });
        };

        search.addEventListener('input', applyFilter);
        applyFilter();
      })();
    </script>
    <?php
});
