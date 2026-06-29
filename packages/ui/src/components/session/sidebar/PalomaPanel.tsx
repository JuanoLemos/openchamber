import React from 'react';
import { Button } from '@/components/ui/button';
import { opencodeClient } from '@/lib/opencode/client';
import { runtimeFetch } from '@/lib/runtime-fetch';
import { useSessionUIStore } from '@/sync/session-ui-store';
import { useSelectionStore } from '@/sync/selection-store';
import { toast } from '@/components/ui';

type PalomaEntry = {
  id: string;
  agent: string;
  desc: string;
  state: string;
};

function parsePalomasTable(text: string): PalomaEntry[] {
  return text.split('\n')
    .filter(line => /^\| P\d+ \|/.test(line))
    .map(line => {
      const cols = line.split('|').map(s => s.trim());
      return {
        id: cols[1] || 'P???',
        agent: cols[3] || '—',
        desc: (cols[4] || '').slice(0, 60),
        state: cols[7] || '📬 Pendiente',
      };
    });
}

export function PalomaPanel(): React.ReactNode {
  const [expanded, setExpanded] = React.useState(false);
  const [palomas, setPalomas] = React.useState<PalomaEntry[]>([]);
  const [loading, setLoading] = React.useState(true);
  const currentSessionId = useSessionUIStore((state) => state.currentSessionId);

  React.useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await runtimeFetch(
          '/api/fs/read?path=doc/arch/palomas.md&optional=true',
          { cache: 'no-store' }
        );
        if (!res.ok) { setLoading(false); return; }
        const text = await res.text();
        if (!cancelled) {
          setPalomas(parsePalomasTable(text));
          setLoading(false);
        }
      } catch {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, []);

  const pending = palomas.filter(p => p.state.includes('📬') || p.state.includes('🟡')).length;
  const total = palomas.length;
  const progress = total > 0 ? Math.round(((total - pending) / total) * 100) : 0;

  const sendCommand = (command: string, args?: string) => {
    if (!currentSessionId) {
      toast.warning('Sin sesión activa', { description: 'Iniciá una sesión de OpenCode primero' });
      return;
    }
    const selection = useSelectionStore.getState().getSessionModelSelection(currentSessionId);
    if (!selection) {
      toast.warning('Comando no enviado', { description: 'Seleccioná un modelo en el chat primero' });
      return;
    }
    opencodeClient.sendCommand({
      id: currentSessionId,
      providerID: selection.providerId,
      modelID: selection.modelId,
      command,
      arguments: args ?? '',
    }).then(() => {
      toast.success('Comando enviado', { description: `${command} ejecutándose` });
    }).catch((e) => {
      toast.error('Error', { description: `${command}: ${e instanceof Error ? e.message : 'desconocido'}` });
    });
  };

  return (
    <div className="border-t border-b border-border/40">
      <button
        type="button"
        onClick={() => setExpanded(!expanded)}
        className="flex w-full items-center justify-between px-3 py-2 text-xs font-medium text-muted-foreground hover:text-foreground transition-colors"
      >
        <span>📬 Palomas {pending > 0 ? `(${pending})` : ''}</span>
        <span className="text-xs">{expanded ? '▾' : '▸'}</span>
      </button>

      {expanded && (
        <div className="px-2 pb-2 space-y-1">
          {palomas.map(p => (
            <div
              key={p.id}
              className="flex items-center gap-2 px-2 py-1 rounded text-xs hover:bg-interactive-hover/50 cursor-default"
            >
              <span className="shrink-0">{p.state.slice(0, 2)}</span>
              <div className="min-w-0 flex-1">
                <div className="truncate font-medium">{p.id} {p.agent}</div>
                <div className="truncate text-muted-foreground">{p.desc}</div>
              </div>
            </div>
          ))}

          <div className="mt-2 px-1">
            <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
              <span>{progress}% ({total - pending}/{total} resueltas)</span>
            </div>
            <div className="h-1.5 w-full rounded-full bg-muted overflow-hidden">
              <div
                className="h-full rounded-full bg-primary transition-all"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>

          <Button
            variant="ghost"
            size="sm"
            className="mt-1 w-full h-7 text-xs"
            onClick={() => sendCommand('/paloma', '--news')}
          >
            🕊️ Ver todas (/paloma --news)
          </Button>
        </div>
      )}
    </div>
  );
}
