import java.util.*;
import org.cloudbus.cloudsim.*;
import org.cloudbus.cloudsim.core.CloudSim;
import org.cloudbus.cloudsim.provisioners.*;

/** Custom static Min-Min cloudlet-to-VM scheduling; not a built-in policy.
 * Single-PE independent tasks, known MI lengths, dedicated VMs, no transfer cost.
 */
public class MinMinScheduling {
    private static final long[] LENGTHS = {12000, 6000, 18000, 3000, 9000, 24000};
    private static final double[] SPEEDS = {1000, 2000, 3000};

    static class MinMinBroker extends DatacenterBroker {
        MinMinBroker(String name) throws Exception { super(name); }

        // The custom policy decides bindings AND submission order. SpaceShared
        // below only executes that queue inside each VM; it is not Min-Min.
        void schedule(List<Cloudlet> tasks, List<Vm> vms) {
            List<Cloudlet> pending = new ArrayList<>(tasks);
            List<Cloudlet> ordered = new ArrayList<>();
            double[] available = new double[vms.size()];
            while (!pending.isEmpty()) {
                double earliest = Double.POSITIVE_INFINITY;
                int chosenTask = -1, chosenVm = -1;
                // Global minimum of available[j] + length[i]/MIPS[j].
                // Strict < makes ties stable: input cloudlet order then VM order.
                for (int i = 0; i < pending.size(); i++) {
                    for (int j = 0; j < vms.size(); j++) {
                        double finish = available[j] + pending.get(i).getCloudletLength() / vms.get(j).getMips();
                        if (finish < earliest) {
                            earliest = finish; chosenTask = i; chosenVm = j;
                        }
                    }
                }
                Cloudlet task = pending.remove(chosenTask);
                task.setGuestId(vms.get(chosenVm).getId());
                available[chosenVm] = earliest;
                ordered.add(task);
                System.out.printf(Locale.ROOT, "PLAN,%d,%d,%.3f%n", task.getCloudletId(), task.getGuestId(), earliest);
            }
            submitCloudletList(ordered);
        }
    }

    public static void main(String[] args) throws Exception {
        String policy = args.length == 0 ? "minmin" : args[0].toLowerCase(Locale.ROOT);
        if (!policy.equals("minmin") && !policy.equals("roundrobin")) {
            throw new IllegalArgumentException("Choose minmin or roundrobin");
        }
        CloudSim.init(1, Calendar.getInstance(), false);
        List<Pe> pes = new ArrayList<>();
        for (int i = 0; i < 4; i++) pes.add(new Pe(i, new PeProvisionerSimple(4000)));
        List<Host> hosts = new ArrayList<>();
        hosts.add(new Host(0, new RamProvisionerSimple(8192), new BwProvisionerSimple(10000),
            1000000, pes, new VmSchedulerTimeShared(pes)));
        DatacenterCharacteristics spec = new DatacenterCharacteristics(
            "x86", "Linux", "Xen", hosts, 5.5, 3.0, 0.05, 0.001, 0.0);
        new Datacenter("LabDatacenter", spec, new VmAllocationPolicySimple(hosts), new LinkedList<Storage>(), 0);
        MinMinBroker broker = new MinMinBroker("LabBroker");
        List<Vm> vms = new ArrayList<>();
        for (int i = 0; i < SPEEDS.length; i++) {
            vms.add(new Vm(i, broker.getId(), SPEEDS[i], 1, 512, 1000, 10000,
                "Xen", new CloudletSchedulerSpaceShared()));
        }
        broker.submitGuestList(vms);
        List<Cloudlet> tasks = new ArrayList<>();
        for (int i = 0; i < LENGTHS.length; i++) {
            UtilizationModel full = new UtilizationModelFull();
            Cloudlet task = new Cloudlet(i, LENGTHS[i], 1, 0, 0, full, full, full);
            task.setUserId(broker.getId());
            tasks.add(task);
        }
        if (policy.equals("minmin")) broker.schedule(tasks, vms);
        else {
            for (int i = 0; i < tasks.size(); i++) tasks.get(i).setGuestId(vms.get(i % vms.size()).getId());
            broker.submitCloudletList(tasks);
        }
        CloudSim.startSimulation();
        CloudSim.stopSimulation();
        List<Cloudlet> done = broker.getCloudletReceivedList();
        if (done.size() != LENGTHS.length) throw new IllegalStateException("Some cloudlets were not completed");
        done.sort(Comparator.comparingInt(Cloudlet::getCloudletId));
        double firstStart = Double.POSITIVE_INFINITY, lastFinish = 0;
        System.out.println("RESULT,cloudlet,vm,cpu_seconds,start,finish");
        for (Cloudlet c : done) {
            if (c.getStatus() != Cloudlet.CloudletStatus.SUCCESS) throw new IllegalStateException("Cloudlet failed");
            firstStart = Math.min(firstStart, c.getExecStartTime());
            lastFinish = Math.max(lastFinish, c.getExecFinishTime());
            System.out.printf(Locale.ROOT, "RESULT,%d,%d,%.3f,%.3f,%.3f%n", c.getCloudletId(),
                c.getGuestId(), c.getActualCPUTime(), c.getExecStartTime(), c.getExecFinishTime());
        }
        System.out.printf(Locale.ROOT, "SUMMARY,%s,completed=%d,makespan=%.3f%n", policy, done.size(), lastFinish-firstStart);
    }
}
