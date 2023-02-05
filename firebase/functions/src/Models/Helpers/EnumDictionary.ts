type StringKeyDictionary<T extends string, U> = {
    [K in T]: U
};

type EnumDictionary<T extends string | symbol | number, U> = {
    [K in T]: U;
};

export {
    StringKeyDictionary,
    EnumDictionary
};
