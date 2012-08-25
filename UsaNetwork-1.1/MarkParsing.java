import java.util.ArrayList;


public class MarkParsing {
	private ArrayList<Path> nodePath;
	private Path currentPath;
	private int flag;
	
	public MarkParsing() {
		this.nodePath = new ArrayList<Path>();
		this.flag = 0;
	}
	//どのパケットもパース
	public void parse(int source, int seqno, int hts, int pni) {
		
		//初めてのパケットだったら初期化
		if (this.flag == 0 || this.pathExists(source) == false) {
			if (pni == 255) {
				this.currentPath = new Path(source, seqno);	//packetにmarkingされてなかったら
			} else {
				System.out.println("************************");
				System.out.println("First Packet from Node:" + source);
				System.out.println("************************");
				this.currentPath = new Path(source, seqno, pni); //else
			}
			this.nodePath.add(this.currentPath);
			this.currentPath.printPath();
			this.flag = 1;
		} else {
			this.currentPath = this.getPath(source);
			int d = seqno - this.currentPath.getSeqNo();
			
			//duplicate packet
			if (d < 1) {
				System.out.println("****************");
				System.out.println("Duplicate Packet");
				System.out.println("****************");
				return;
			} else {
				this.currentPath.setSeqNo(seqno);
			}
			
			//no packet loss
			if (d == 1) {
				//はじめてこのpassノードIDから来ていたら
				if (pni == 255) {
					//System.out.println("Success");
				} else {
					if (this.currentPath.get(this.currentPath.size() - 2) != 0) {
						this.currentPath.addSlot(hts, pni);
					} else if (this.currentPath.routeSwitched(hts, pni)) {
						this.currentPath.setSlot(hts, pni);
						this.currentPath.clear(hts);
						System.out.println("**************");
						System.out.println("Route Switch!!");
						System.out.println("**************");
					}
					this.currentPath.printPath();	
				}
			} 
			
			//packet loss detected	
			else if (d > 1) { 
				System.out.println("*************");
				System.out.println("Packet Loss!!");
				System.out.println("*************");
				if (pni == 255) {
					//System.out.println("Success");
				} else {
					if (this.currentPath.get(this.currentPath.size() - 2) != 0) {
					this.currentPath.addSlot(hts, pni);
					this.currentPath.printPath();
					} else if (this.currentPath.routeSwitched(hts, pni)) {
						this.currentPath.clear(hts - d + 1);
						this.currentPath.setSlot(hts, pni);
						System.out.println("**************");
						System.out.println("Route Switch!!");
						System.out.println("**************");
					}
				}
			}
		}
	}
	
	
	//pathが存在するかどうか
	public boolean pathExists(int source) {
		for (int i=0; i<this.nodePath.size(); i++) {
			if (this.nodePath.get(i).get(0) == source) {
				return true;
			}
		}
		return false;
	}
	
	//sourceのpathをgetする
	public Path getPath(int source) {
		int i;
		
		for (i=0; i<this.nodePath.size(); i++)
			if (this.nodePath.get(i).get(0) == source) break;
		
		return this.nodePath.get(i);
	}
}
