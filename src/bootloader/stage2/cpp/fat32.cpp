#include "fat.hpp"
#include "utils.hpp"

uint32_t fat::ClusterToLBA(uint32_t clusterNum, uint32_t dataStartLBA, BiosParameterBlock* BPB) {
    return dataStartLBA + utils::u32_multiply(BPB->SectorsPerCluster, clusterNum - 2);
}
