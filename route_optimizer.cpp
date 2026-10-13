/**
 * Warehouse Route Optimizer & Picklist Engine
 * Language: C++ (C++17)
 * Description: Optimizes item picking routes inside fulfillment centers using
 *              priority queues and spatial location coordinates.
 */

#include <iostream>
#include <vector>
#include <queue>
#include <string>
#include <cmath>
#include <algorithm>
#include <memory>

struct WarehouseLocation {
    int aisle;
    int shelf;
    int bin;

    double distanceTo(const WarehouseLocation& other) const {
        return std::sqrt(std::pow(aisle - other.aisle, 2) +
                         std::pow(shelf - other.shelf, 2) +
                         std::pow(bin - other.bin, 2));
    }
};

struct PickTask {
    std::string sku;
    int quantity;
    WarehouseLocation loc;
    int priority; // 1 = High, 5 = Low

    // Priority queue comparator: lower priority value or closer aisle comes first
    bool operator>(const PickTask& other) const {
        if (priority != other.priority) {
            return priority > other.priority;
        }
        return loc.aisle > other.loc.aisle;
    }
};

class PickingRoutePlanner {
private:
    WarehouseLocation depotLocation;
    std::priority_queue<PickTask, std::vector<PickTask>, std::greater<PickTask>> taskQueue;

public:
    explicit PickingRoutePlanner(WarehouseLocation depot) : depotLocation(depot) {}

    void addPickTask(const std::string& sku, int qty, WarehouseLocation loc, int prio) {
        PickTask task{sku, qty, loc, prio};
        taskQueue.push(task);
        std::cout << "[CPP Planner] Added pick task: " << sku << " (Qty: " << qty 
                  << ") at Aisle " << loc.aisle << ", Shelf " << loc.shelf << "\n";
    }

    double generateOptimizedRoute() {
        std::cout << "\n--- Generating Warehouse Picklist Route ---\n";
        WarehouseLocation currentPos = depotLocation;
        double totalDistance = 0.0;
        int step = 1;

        while (!taskQueue.empty()) {
            PickTask task = taskQueue.top();
            taskQueue.pop();

            double stepDist = currentPos.distanceTo(task.loc);
            totalDistance += stepDist;
            currentPos = task.loc;

            std::cout << "Step " << step++ << ": Pick SKU [" << task.sku 
                      << "] x" << task.quantity << " at [Aisle " << task.loc.aisle 
                      << ", Shelf " << task.loc.shelf << ", Bin " << task.loc.bin 
                      << "] | Leg Distance: " << stepDist << " meters\n";
        }

        double returnDist = currentPos.distanceTo(depotLocation);
        totalDistance += returnDist;
        std::cout << "Step " << step << ": Return to Packing Depot | Distance: " 
                  << returnDist << " meters\n";
        std::cout << "Total Route Travel Distance: " << totalDistance << " meters\n";
        std::cout << "-------------------------------------------\n\n";

        return totalDistance;
    }

    size_t getRemainingTasksCount() const {
        return taskQueue.size();
    }
};

int main() {
    std::cout << "Initializing C++ Warehouse Fulfillment Optimizer...\n\n";

    WarehouseLocation depot{0, 0, 0};
    PickingRoutePlanner planner(depot);

    planner.addPickTask("SKU-A100", 2, WarehouseLocation{3, 12, 1}, 1);
    planner.addPickTask("SKU-B200", 1, WarehouseLocation{1, 4, 3}, 2);
    planner.addPickTask("SKU-C300", 5, WarehouseLocation{8, 2, 2}, 1);
    planner.addPickTask("SKU-D400", 1, WarehouseLocation{2, 10, 4}, 3);

    double totalMeters = planner.generateOptimizedRoute();
    std::cout << "Optimization complete. Route efficiency factor calculated.\n";

    return 0;
}