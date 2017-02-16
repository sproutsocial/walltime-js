export declare function init(rules?: any, zones?: any): void;
export declare function addRulesZones(rules?: any, zones?: any): void;
export declare function setTimeZone(name?: string): void;
export declare function Date(y?: number, m?: number, d?: number, h?: number, mi?: number, s?: number, ms?: number): Date;
export declare function UTCToWallTime(dt?: Date, zoneName?: string): Date;
export declare function WallTimeToUTC(zoneName?: string, y?:number, m?: number, d?: number, h?: number, mi?: number, s?: number, ms?: number): Date;
export declare function IsAmbiguous(zoneName?: string, y?: number, m?: number, d?: number, h?: number, mi?: number): boolean;
