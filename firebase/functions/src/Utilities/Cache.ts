import { Competition } from "../Models/Competition";
import { User } from "../Models/User";

export class InvocationCacheContainer {

    private static instance: InvocationCacheContainer;

    invocationCaches: Map<string, InvocationCache>

    constructor() {
        this.invocationCaches = new Map();
    }

    public static getInstance(): InvocationCacheContainer {
        if (!InvocationCacheContainer.instance) {
            InvocationCacheContainer.instance = new InvocationCacheContainer();
        }
        return InvocationCacheContainer.instance;
    }
}

export class InvocationCache {
    users: User[];
    competitions: Competition[];

    constructor() {
        this.users = [];
        this.competitions = [];
    }
}