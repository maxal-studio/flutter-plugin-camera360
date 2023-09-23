#include "Stitcher.h"

/*
Copyright (c) 2021, azad prajapat
https://github.com/azadprajapat/opencv_awesome/blob/master/android/src/main/jni/native_opencv.cpp

Copyright (c) 2022, 小島 伊織 / Iori Kojima
*/

// 複数の画像をパノラマ画像にstitchする
#include "opencv2/opencv.hpp"
#include "opencv2/stitching.hpp"
#include "opencv2/imgproc.hpp"
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

using namespace cv;
using namespace std;

// @interface Cropping : NSObject
// + (bool) cropWithMat: (const cv::Mat &)src andResult:(cv::Mat &)dest;
// @end

// CROPPPING STARTS HERES
bool checkBlackRow(const cv::Mat &roi, int y, const cv::Rect &rect)
{
    int zeroCount = 0;
    for (int x = rect.x; x < rect.width; x++)
    {
        if (roi.at<uchar>(y, x) == 0)
        {
            zeroCount++;
        }
    }
    if ((zeroCount / (float)roi.cols) > 0.05)
    {
        return false;
    }
    return true;
}

bool checkBlackColumn(const cv::Mat &roi, int x, const cv::Rect &rect)
{
    int zeroCount = 0;
    for (int y = rect.y; y < rect.height; y++)
    {
        if (roi.at<uchar>(y, x) == 0)
        {
            zeroCount++;
        }
    }
    if ((zeroCount / (float)roi.rows) > 0.05)
    {
        return false;
    }
    return true;
}

bool cropWithMat(const cv::Mat src, cv::Mat &dest)
{
    cv::Mat gray;
    cvtColor(src, gray, cv::COLOR_BGRA2GRAY); // convert src to gray

    cv::Rect roiRect(0, 0, gray.cols, gray.rows); // start as the source image - ROI is the complete SRC-Image

    while (1)
    {
        bool isTopNotBlack = checkBlackRow(gray, roiRect.y, roiRect);
        bool isLeftNotBlack = checkBlackColumn(gray, roiRect.x, roiRect);
        bool isBottomNotBlack = checkBlackRow(gray, roiRect.y + roiRect.height - 1, roiRect);
        bool isRightNotBlack = checkBlackColumn(gray, roiRect.x + roiRect.width - 1, roiRect);

        if (isTopNotBlack && isLeftNotBlack && isBottomNotBlack && isRightNotBlack)
        {
            printf("%d %d %d %d \n", roiRect.x, roiRect.y, roiRect.width, roiRect.height);

            cv::Mat imageReference = src(roiRect);
            imageReference.copyTo(dest);
            return true;
        }
        // If not, scale ROI down
        // if x is increased, width has to be decreased to compensate
        if (!isLeftNotBlack)
        {
            roiRect.x++;
            roiRect.width--;
        }
        // same is valid for y
        if (!isTopNotBlack)
        {
            roiRect.y++;
            roiRect.height--;
        }
        if (!isRightNotBlack)
        {
            roiRect.width--;
        }
        if (!isBottomNotBlack)
        {
            roiRect.height--;
        }
        if (roiRect.width <= 0 || roiRect.height <= 0)
        {
            printf("Cropping failed");
            return false;
        }
    }
}
// CROPPPING ENDS HERES

struct tokens : ctype<char>
{
    tokens() : std::ctype<char>(get_table()) {}

    static std::ctype_base::mask const *get_table()
    {
        typedef std::ctype<char> cctype;
        static const cctype::mask *const_rc = cctype::classic_table();

        static cctype::mask rc[cctype::table_size];
        std::memcpy(rc, const_rc, cctype::table_size * sizeof(cctype::mask));

        rc[','] = ctype_base::space;
        rc[' '] = ctype_base::space;
        return &rc[0];
    }
};
vector<string> getpathlist(string path_string)
{
    string sub_string = path_string.substr(1, path_string.length() - 2);
    stringstream ss(sub_string);
    ss.imbue(locale(locale(), new tokens()));
    istream_iterator<std::string> begin(ss);
    istream_iterator<std::string> end;
    vector<std::string> pathlist(begin, end);
    return pathlist;
}

Mat process_stitching(vector<Mat> imgVec)
{
    Mat result = Mat();
    Stitcher::Mode mode = Stitcher::PANORAMA;
    Ptr<Stitcher> stitcher = Stitcher::create(mode);
    Stitcher::Status status = stitcher->stitch(imgVec, result);

    // If stitching failed
    if (status != Stitcher::OK)
    {
        // hconcat(imgVec, result);
        printf("Stitching error: %d\n", status);
        return Mat();
    }

    printf("Stitching success here\n");
    cvtColor(result, result, COLOR_RGB2BGR);
    return result;
}

vector<Mat> convert_to_matlist(vector<string> img_list, bool isvertical)
{
    vector<Mat> imgVec;
    for (auto k = img_list.begin(); k != img_list.end(); ++k)
    {
        String path = *k;
        Mat input = imread(path);
        Mat newimage;
        // Convert to a 3 channel Mat to use with Stitcher module
        cvtColor(input, newimage, COLOR_BGR2RGB, 3);
        // Reduce the resolution for fast computation
        float scale = 1000.0f / input.rows;
        // resize(newimage, newimage, Size(scale * input.rows, scale * input.cols));
        if (isvertical)
            rotate(newimage, newimage, ROTATE_90_COUNTERCLOCKWISE);
        imgVec.push_back(newimage);
    }
    return imgVec;
}

bool stitch(char *inputImagePath, char *outputImagePath, bool cropped)
{
    string input_path_string = inputImagePath;
    vector<string> image_vector_list = getpathlist(input_path_string);
    vector<Mat> mat_list;
    mat_list = convert_to_matlist(image_vector_list, false);
    Mat result = process_stitching(mat_list);

    // Check if stitching failed
    if (result.empty())
    {
        return false;
    }

    if (cropped == true)
    {
        // Crop black background
        Mat withoutBlackBg;
        if (cropWithMat(result, withoutBlackBg) == true)
        {
            imwrite(outputImagePath, withoutBlackBg);
            printf("Image cropped successfully\n");
            return true;
        }
        else
        {
            printf("Image cropping failed\n");
            return false;
        }
    }
    else
    {
        Mat cropped_image;
        result(Rect(0, 0, result.cols, result.rows)).copyTo(cropped_image);
        imwrite(outputImagePath, cropped_image);
        return true;
    }
}
