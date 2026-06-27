export interface DiligenciaCommand {
  label: string;
  description: string;
  command: string;
  arguments?: string;
}

export interface DiligenciaCommandGroup {
  verb: string;
  icon: string;
  emoji: string;
  commands: DiligenciaCommand[];
}

export const DILIGENCIA_COMMAND_GROUPS: DiligenciaCommandGroup[] = [
  {
    verb: 'CREAR',
    icon: 'pen',
    emoji: '✏️',
    commands: [
      { label: '/adaptar', description: 'Adaptar proyecto a Diligencia', command: '/adaptar' },
      { label: '/+rm', description: 'Agregar item al ROADMAP', command: '/+rm' },
      { label: '/doc', description: 'Crear/actualizar guía o mecánica', command: '/doc' },
      { label: '/propagar', description: 'Propagar updates a proyectos', command: '/propagar' },
    ],
  },
  {
    verb: 'PLANIFICAR',
    icon: 'brain',
    emoji: '📋',
    commands: [
      { label: '/plan', description: 'Planificar tarea o grupo (--ola)', command: '/plan' },
      { label: '/rm', description: 'Top 10 tareas por prioridad', command: '/rm' },
      { label: '/next', description: 'Plan de ejecución por olas', command: '/next' },
      { label: '/consejo', description: 'Consultar al consejero', command: '/consejo' },
      { label: '/circuito', description: 'Revisar integridad lógica y UX', command: '/circuito' },
      { label: '/explica', description: 'Explicar concepto', command: '/explica' },
      { label: '/foco', description: 'Enfocar agente en área', command: '/foco' },
      { label: '/head', description: 'Preparar edición de sección', command: '/head' },
    ],
  },
  {
    verb: 'EJECUTAR',
    icon: 'zap',
    emoji: '⚡',
    commands: [
      { label: '/commit --push', description: 'Commitear y pushear', command: '/commit', arguments: '--push' },
      { label: '/version', description: 'Cerrar sesión', command: '/version' },
      { label: '/reanudar', description: 'Recuperar sesión', command: '/reanudar' },
      { label: '/estado', description: 'Reporte rápido del proyecto', command: '/estado' },
      { label: '/backup', description: 'Backup (--all zip)', command: '/backup' },
      { label: '/updoc', description: 'Actualizar documentación', command: '/updoc' },
    ],
  },
  {
    verb: 'REVISAR',
    icon: 'search',
    emoji: '🔍',
    commands: [
      { label: '/informe-salud', description: 'Salud de todos los proyectos', command: '/informe-salud' },
      { label: '/reportar', description: 'Reportar bug o incidente', command: '/reportar' },
      { label: '/mutacion', description: 'Absorber mutaciones externas', command: '/mutacion' },
      { label: '/revision', description: 'Revisar mutaciones del proyecto', command: '/revision' },
      { label: '/debug', description: 'Análisis profundo de código', command: '/debug' },
    ],
  },
  {
    verb: 'CUIDAR',
    icon: 'heart',
    emoji: '🛡️',
    commands: [
      { label: '/doctor', description: 'Cuidado integral (8 fases)', command: '/doctor' },
      { label: '/health', description: 'Verificar sintaxis', command: '/health' },
      { label: '/diligencia-check', description: 'Validar estructura Diligencia', command: '/diligencia-check' },
      { label: '/deprecar', description: 'Mover obsoleto a .old/', command: '/deprecar' },
      { label: '/limpiar', description: 'Eliminar temporales', command: '/limpiar' },
    ],
  },
];
