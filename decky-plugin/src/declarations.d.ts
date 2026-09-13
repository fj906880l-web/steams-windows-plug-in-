// TypeScript ambient definitions for Decky Loader Plugin environment

declare module "react" {
  export type ReactNode = any;
  export type CSSProperties = Record<string, any>;
  export interface VFC<P = {}> {
    (props: P): any;
  }
  export interface FC<P = {}> {
    (props: P): any;
  }
  export function useState<T>(initialState: T | (() => T)): [T, (newState: T | ((prev: T) => T)) => void];
  export function useEffect(effect: () => void | (() => void), deps?: any[]): void;
  const React: any;
  export default React;
}

declare module "react/jsx-runtime" {
  export const jsx: any;
  export const jsxs: any;
  export const Fragment: any;
}

declare namespace JSX {
  interface IntrinsicElements {
    [elemName: string]: any;
  }
  interface Element {
    [key: string]: any;
  }
}

declare module "decky-frontend-lib" {
  export interface ServerAPI {
    callPluginMethod<T = any, R = any>(methodName: string, args: T): Promise<{ success: boolean; result: R }>;
    toaster: {
      toast(props: any): void;
    };
  }

  export const PanelSection: any;
  export const PanelSectionRow: any;
  export const ButtonItem: any;
  export const Field: any;
  export const ToggleField: any;
  export const DropdownItem: any;
  export const staticClasses: Record<string, string>;

  export function definePlugin(fn: (serverAPI: ServerAPI) => any): any;
}

declare module "react-icons/fa" {
  export const FaShieldAlt: any;
  export const FaGamepad: any;
  export const FaCloud: any;
  export const FaBolt: any;
  export const FaCheckCircle: any;
  export const FaWifi: any;
}
