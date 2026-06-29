import React from 'react';
import { Button } from '@/components/ui/button';
import { opencodeClient } from '@/lib/opencode/client';
import { useSessionUIStore } from '@/sync/session-ui-store';
import { useSelectionStore } from '@/sync/selection-store';
import { toast } from '@/components/ui';

export function PalomaPanel(): React.ReactNode {
  const [expanded, setExpanded] = React.useState(false);
  const currentSessionId = useSessionUIStore((state) => state.currentSessionId);

  const palomas = [
    { id: 'P001', agent: '@documentador', desc: '/documentar --legales', state: '✅ Actuado' },
    { id: 'P002', agent: '@documentador', desc: '/documentar (completo)', state: '🟡 En revisión' },
    { id: 'P003', agent: '@documentador', desc: 'Manifiesto Diligencia', state: '✅ Actuado' },
    { id: 'P004', agent: '@documentador', desc: '/documentar --estructura', state: '📬 Pendiente' },
  ];

  const pending = palomas.filter(p => p.state === '📬 Pendiente' || p.state === '🟡 En revisión').length;
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
