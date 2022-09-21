interface Array<T> {
    remove(elem: T): Array<T>;
}
  
if (!Array.prototype.remove) {
    // eslint-disable-next-line no-extend-native
    Array.prototype.remove = function<T>(this: T[], elem: T): T[] {
        const index = this.indexOf(elem, 0);
        if (index > -1) {
            this.splice(index, 1);
        }
        return this;
    };
}
