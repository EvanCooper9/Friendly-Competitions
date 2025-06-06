interface Date {
    isFirstOfMonth(): boolean;
    isLastOfMonth(): boolean;
}

Date.prototype.isFirstOfMonth = function(): boolean {
    return this.getUTCDate() === 1;
}

Date.prototype.isLastOfMonth = function(): boolean {
    const nextDay = new Date(this.getUTCFullYear(), this.getUTCMonth() + 1, 0);
    return this.getUTCDate() === nextDay.getUTCDate();
}