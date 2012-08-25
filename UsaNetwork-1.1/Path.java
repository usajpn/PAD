import java.util.ArrayList;


public class Path extends ArrayList<Integer>{
	
	public Path(int source, int seqno) {
		this.add(source);
		this.add(seqno);
	}
	
	public Path(int source, int seqno, int pni) {
		this.add(source);
		this.add(pni);
		this.add(seqno);
	}
	
	public void setSeqNo(int seqno) {
		this.set(this.size() - 1, seqno);
	}
	
	public int getSeqNo() {
		return this.get(this.size() - 1);
	}
	
	public boolean routeSwitched(int hts, int pni) {
		if (this.get(hts) != pni) return true;
		return false;
	}
	
	public void setSlot(int hts, int pni) {
		this.set(hts, pni);
	}
	
	public void addSlot(int hts, int pni) {
		this.add(hts, pni);
	}
	
	public void clear(int hts) {
		this.removeRange(hts + 1, this.size() - 2);
	}

	public boolean firstNodeSlot(int pni) {
		if (this.indexOf(pni) != -1) {
			if (this.indexOf(pni) == (this.size() - 1)) {
				return true;
			}
			return false;
		}
		return true;
	}
	
	public void printPath() {
		System.out.println("************************************");
		System.out.print("[Path of Node "+ this.get(0) + "] |");
		for (int i=0; i<this.size()-1; i++) {
			System.out.print(this.get(i) + "|");
		}
		System.out.println(" Seq:" + this.getSeqNo());
		System.out.println("************************************");
	}
}
