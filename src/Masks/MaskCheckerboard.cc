#include "CellManager.h"

#include <iostream>
#include <fstream>
#include <numeric>
#include <iomanip>

namespace ORB_SLAM3 
{

CellManager& CellManager::getInstance()
{
    static CellManager instance;
    return instance;
}

void CellManager::incrementCell()
{
    elapsed_cells++;  // Increment the frame's elapsed Cells
}

bool CellManager::skipCell(const feature_extraction_state_t& cell)
{
    bool skip = false;

    // Populate pyramid level info if needed
    if (pyramid_levels.size() < (cell.level + 1))
    {
        pyramid_levels.push_back({cell.nRows, cell.nCols});
    }

    if (enableOasis)
    {
        int blockSize = 4;
        bool isBlack = ((cell.row / blockSize + cell.col / blockSize) % 2 == 0);
        if (!isBlack)
            skip = true;

        if (skip_frames)
            skip = true;
    }

    if (skip)
    {
        elapsed_cells--;  // Don't count skipped cell
    }

    return skip;
}

void CellManager::endFrame(const double& frame_num, double actualFrameTime)
{
    if (skip_frames)
    {
        std::cout << "Skipped/Dropped frame " << frame_num << std::endl;
        skip_frames--;
    }

    if (elapsed_cells == 0)
    {
        frame_budget = static_cast<int>(1.0 / actualFrameTime * getAverageCellsPerFrame());
        return;
    }

    if (skip_frames)
    {
        elapsed_cells = 0;
        return;
    }

    cells_per_frame.push_back(elapsed_cells);

    static bool stereo_slam = (elapsed_cells > (pyramid_levels[0].nRows * pyramid_levels[0].nCols) * 1.8);

    const double time_per_cell = (actualFrameTime / getAverageCellsPerFrame());
    const double frame_time = 50.0f; // ms
    double frame_budget = static_cast<int>(frame_time / time_per_cell);

    if (stereo_slam)
        frame_budget /= 2;

    if (actualFrameTime > frame_time)
    {
        double frame_time_remaining = actualFrameTime;
        size_t frames_over_budget = 0;

        while (frame_time_remaining > frame_time)
        {
            frames_over_budget++;
            frame_time_remaining -= frame_time;
        }

        skip_frames = static_cast<int>(frames_over_budget);

        const double remaining_budget = (2 * frame_time) - (actualFrameTime - frame_time * (skip_frames - 1));
        if (skip_frames) skip_frames--;
        frame_budget = static_cast<int>(remaining_budget / time_per_cell);
    }

    if (pyramid_levels.empty())
    {
        std::cout << "No pyramid levels found, can't set FOV_MASK" << std::endl;
        return;
    }

    const int largest_mask = std::max(pyramid_levels[0].nRows, pyramid_levels[0].nCols) + 1;
    FOV_MASK.height = largest_mask + 1;
    FOV_MASK.width = largest_mask + 1;

    for (int mask = 2; mask < largest_mask; mask++)
    {
        const int maskWidth = mask;
        const int maskHeight = mask;

        int cells_in_mask = 0;
        for (int level = 0; level < pyramid_levels.size(); level++)
        {
            int cells_at_level = pyramid_levels[level].nRows * pyramid_levels[level].nCols;
            cells_in_mask += std::min(cells_at_level, maskWidth * maskHeight);
        }

        if (cells_in_mask < frame_budget)
            continue;
        else
        {
            int prev_mask = mask - 1;
            FOV_MASK.height = prev_mask;
            FOV_MASK.width = prev_mask;
            break;
        }
    }

    enableOasis = true;
    printStats(frame_num, actualFrameTime);
    elapsed_cells = 0;
}

double CellManager::getAverageCellsPerFrame() const
{
    if (cells_per_frame.empty()) return 0.0;
    int total_cells = std::accumulate(cells_per_frame.begin(), cells_per_frame.end(), 0);
    return static_cast<double>(total_cells) / cells_per_frame.size();
}

void CellManager::printStats(const double& frame_num, const double& frameTimestamp) const
{
    std::ofstream file("cellManager.txt", std::ios::app);
    if (!file)
    {
        std::cerr << "Failed to open cellManager.txt" << std::endl;
        return;
    }

    static bool once = true;
    if (once)
    {
        file << " - Pyramid Level Cells: \n";
        for (size_t i = 0; i < pyramid_levels.size(); i++)
        {
            file << "   - Level " << i << ": "
                 << pyramid_levels[i].nCols << "x"
                 << pyramid_levels[i].nRows << "\n";
        }

        file << (enableOasis ? " - Oasis Enabled" : " - Oasis Disabled") << std::endl;
        once = false;
    }

    file << "Frame " << std::fixed << std::setprecision(9) << frame_num
         << " finished in " << frameTimestamp << " ms stats:\n";
    file << " - Recorded Frames: " << cells_per_frame.size() << "\n";
    file << " - Elapsed Cells: " << elapsed_cells << "\n";
    file << " - Average Cells Per Frame: " << getAverageCellsPerFrame() << "\n";
    file << " - Frame Budget in Cells: " << frame_budget << "\n";
    file << " - FOV Mask: " << FOV_MASK.width << "x" << FOV_MASK.height << "\n";
}

} // namespace ORB_SLAM3
