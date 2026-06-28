import React from 'react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip';
import { opencodeClient } from '@/lib/opencode/client';
import { useSessionUIStore } from '@/sync/session-ui-store';
import { useSelectionStore } from '@/sync/selection-store';
import { toast } from '@/components/ui';
import { DILIGENCIA_COMMAND_GROUPS } from '@/lib/diligencia/commands';

export function DiligenciaCommandBar(): React.ReactNode {
  const currentSessionId = useSessionUIStore((state) => state.currentSessionId);

  const sendCommand = React.useCallback(
    (command: string, args?: string) => {
      if (!currentSessionId) return;
      const selection = useSelectionStore.getState().getSessionModelSelection(currentSessionId);
      if (!selection) {
        toast.warning('Comando no enviado', { description: 'Seleccioná un proveedor y modelo en el chat primero' });
        return;
      }
      void opencodeClient.sendCommand({
        id: currentSessionId,
        providerID: selection.providerId,
        modelID: selection.modelId,
        command,
        arguments: args ?? '',
      });
    },
    [currentSessionId],
  );

  return (
    <div className="flex flex-wrap items-center gap-0.5 px-1.5 py-1">
      {DILIGENCIA_COMMAND_GROUPS.map((group) => (
        <DropdownMenu key={group.verb}>
          <Tooltip>
            <TooltipTrigger asChild>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-7 gap-1 px-1.5 text-xs font-medium text-muted-foreground hover:text-foreground"
                >
                  <span className="text-xs">{group.emoji}</span>
                  <span className="hidden sm:inline">{group.verb}</span>
                </Button>
              </DropdownMenuTrigger>
            </TooltipTrigger>
            <TooltipContent side="top" sideOffset={4}>
              <p>{group.verb} — {group.commands.length} comandos</p>
            </TooltipContent>
          </Tooltip>
          <DropdownMenuContent align="start" className="min-w-[200px]">
            {group.commands.map((cmd, i) => (
              <React.Fragment key={cmd.label}>
                {i > 0 && i % 3 === 0 && <DropdownMenuSeparator />}
                <DropdownMenuItem
                  onSelect={() => sendCommand(cmd.command, cmd.arguments)}
                  className="flex items-center gap-2 py-1.5"
                >
                  <code className="text-xs font-medium">{cmd.label}</code>
                  <span className="ml-auto text-xs text-muted-foreground truncate max-w-[140px]">
                    {cmd.description}
                  </span>
                </DropdownMenuItem>
              </React.Fragment>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>
      ))}
    </div>
  );
}
