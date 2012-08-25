/*
 * @author usa
 */

interface PadCache<t> {
    command void flush();
    command bool lookup(t item);
    command void insert(t item);
	command void update(t item);
	command bool sequential(t item);
}
